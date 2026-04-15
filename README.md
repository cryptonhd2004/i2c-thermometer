# I2C Thermometer implementation

### Členové Týmu

* Adam Solovic
* Tomáš Střelec
* David Šindelář


### Abstrakt

### I2C komunikace
Na naší bastldesce Nexys-A7-50T funguje komunikace s naším teplotním senzorem ADT7420 pomocí I2C sběrnice. Tato sběrnice, vyvinutá holandskou firmou Philips, funguje na bázi master-slave, kdy zařízení kterým chceme ovladát uvedeme do role master a ovládané zařízení bude slave. Při I2C komunikaci se každý rámec odeslaný masterem posílá na všechny zařízení v rámci dané I2C sběrnice, proto vždy musíme specifikovat danou hexadecimální adresu tohoto zařízení a taky flag, který bude 1 když budeme číst ze zařízení nebo 0 když budeme zapisovat do zařízení. Poté až může začít datový přenos. 
Když bychom chtěli něco zapsat do zařízení, musíme poslat adresu daného registru a poté data které chceme zapsat do daného registru. Při čtení je to ale jiné. Nejdříve pošleme adresu registru ze kterého chceme číst, poté pošleme I2C žádost o restart a znovu odešleme novou žádost o čtení. Pokud vynecháme I2C žádost o restart, hodnota v adresovaném registru bude 0x00. Některé registry ukládají 16bitové hodnoty jako jeden pár 8bitových hodnot a proto ADT7420 automaticky přidá jeden bit do adresy registru při přečtení z prvního registru. 
Toho budeme využívat my, jelikož čteme z registrů Temperature value a ty jsou: Temperature value most significant byte a Temperature value least significant byte. Díky tomuto automatickému přičítaní můžeme číst z obou registrů zároveň.



### FORMÁT PŘIJÍMANÝCH DAT

Tyto hodnoty bereme z registrů s názvem Temperature value least significant byte a Temperature value most significant byte s adresami 0x00 a 0x01. Začneme s tím, že z registrů budeme chtít číst 13-bitové hodnoty teploty. Oba registry dohromady mají velikost 16 bit, ale my budeme pracovat jen v 13-bitovém režimu, jelikož po sensoru nevyžadujeme takovou přesnost. Kdybychom chtěli, tak bychom mohli pracovat i v 16-bitovém režimu, který byl přesnější, ale jak už bylo zmíněno, na naše poměry stačí jen 13-bitový. Když tedy budeme pracovat s 13-bitovým výsledkem tak formát přijímaných dat bude vypadat následovně:

3-14 bit --- už převedená hodnota naměřené teploty
15 bit	 --- znaménko převedené hodnoty(jestli teplota je pod nulou či nad nulou)

Tímto formátem budeme číst a převádět hodnoty naměřených teplot. Jeden LSB má ve 13-bitovém čtení hodnotu 0.0625°C. 
Přečtenou hodnotu z registru musíme poté převést z binárního čísla na hexadecimální a to poté převést na decimální a to poté jen v kódě vynásobíme 0.0625. Tím získáme změřenou teplotu ve stupních celsium.

Příklad:

(0 0001 1001 0000) --- tuto hodnotu přijmeme z registru

0 0001 1001 0000 ===> 0x190 --- zde ji převedeme do hexadecimálu

0x190 ===> 400 --- zde ji převedeme do decimálu

400 * 0.0625 --- zde vynásobíme 

25°C je naše výsledná teplota. 


### Schéma  
<img width="1314" height="553" alt="thermometer_top" src="https://github.com/user-attachments/assets/65ecb13e-2c35-42c8-bce4-ba250fc872fc" />

### Zdroje
Constrain soubor pro Nexys A7 50T https://github.com/Digilent/digilent-xdc/blob/master/Nexys-A7-50T-Master.xdc
Verilog inspirace: https://github.com/FPGADude/Digital-Design/tree/main/FPGA%20Projects/NexysA7_Temp_Sensor_I2C
Datasheet pro naši desku Nexys A7 50T: https://digilent.com/reference/_media/reference/programmable-logic/nexys-a7/nexys-a7_rm.pdf
Datasheet pro ADT7420: https://www.analog.com/media/en/technical-documentation/data-sheets/ADT7420.pdf
