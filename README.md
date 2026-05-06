# I2C Thermometer implementation
## Plakát

[Plakát](temp sensor - top documentation/POSTER.png)
https://github.com/cryptonhd2004/i2c-thermometer/blob/697cef1a8661db91c687b03d31bc93de2b2695a3/temp%20sensor%20-%20top%20documentation/POSTER.png

### Členové Týmu

* Adam Solovic
* Tomáš Střelec
* David Šindelář


## Abstrakt

### Úvod

V našem projektu jsme si vybrali vlastní téma, teplotní senzor ADT7420. Zvolili jsme ho z důvodu minulé zkušenosti jednoho našeho člena s teplotními senzory. 

### Základní informace o senzoru

-- Velikost senzoru: 4 mm x 4 mm

-- Součásti senzoru: Vnitřní zdroj stabilního napětí, teplotní senzor a 16 bitový ADC převodník

-- Přesnost senzoru: 
* +-0.20°C od -10°C do +85°C na 3.0 voltech
* +-0.25°C od -20°C do +105°C na 2.7 až 3.3 voltech
* 13 bitový rozsah (přesnost 0.0625°C)
* 16 bitový rozsah (přesnost 0.0078°C)
                      
-- Pracovní rozsahy:
* Teplotní --- (-40)°C až +150°C
* Napěťové --- 2.7 V až 5.5 V

-- 4 pracovní režimy
* Normal mode
* One-shot mode
* 1 SPS mode
* Shutdown mode

-- 10 pracovních registrů

-- Komunikace se senzorem probíhá přes I2C sběrnici

### Popis pinů

<img width="553" height="553" alt="ADT7420-piny(4)" src="temp sensor - top documentation/ADT7420-piny.png" />

| Číslo pinu | Označení | Popis |
|------------| ---------|----|
|`1`|SCL|I2C sériový clock výstup - využíváme ho k určení okamžiku kdy čteme nebo zapisujeme data do jednotlivých registrů|
|`2`|SDA|I2C sériový datový výstup - na tomto pinu probíhá přenos dat do a z našeho senzoru|
|`3`|A0|I2C adresní pin - musí být připojený na Vdd nebo ground pro získání I2C adresy|
|`4`|A1|I2C adresní pin - musí být připojený na Vdd nebo ground pro získání I2C adresy|
|`5-8`|NC|NEPŘIPOJEN|
|`9`|INT|Indikátor překročení teplotních rozsahů|
|`10`|CT|Indikátor kritického překročení teplotních rozměrů|
|`11`|GND|Analogový a digitální ground|
|`12`|Vdd|Přivod napětí 2.7 V až 5V |
|`13-16`|NC|NEPŘIPOJEN|
|`17`|EP|Odhalený pin - je nutné aby tento pin byl připojen na ground nebo ponechaný sám o sobě|

### I2C komunikace
Na naší vývojové desce Nexys-A7-50T funguje komunikace s naším teplotním senzorem ADT7420 pomocí I2C sběrnice. Tato sběrnice, vyvinutá holandskou firmou Philips, funguje na bázi master-slave, kdy zařízení kterým chceme ovladát uvedeme do role master a ovládané zařízení bude slave. Při I2C komunikaci se každý rámec odeslaný masterem posílá na všechny zařízení v rámci dané I2C sběrnice, proto vždy musíme specifikovat danou hexadecimální adresu tohoto zařízení a taky flag, který bude 1 když budeme číst ze zařízení nebo 0 když budeme zapisovat do zařízení. Poté až může začít datový přenos. 
Když bychom chtěli něco zapsat do zařízení, musíme poslat adresu daného registru a poté data které chceme zapsat do daného registru. Při čtení je to ale jiné. Nejdříve pošleme adresu registru ze kterého chceme číst, poté pošleme I2C žádost o restart a znovu odešleme novou žádost o čtení. Pokud vynecháme I2C žádost o restart, hodnota v adresovaném registru bude 0x00. Některé registry ukládají 16bitové hodnoty jako jeden pár 8bitových hodnot a proto ADT7420 automaticky přidá jeden bit do adresy registru při přečtení z prvního registru. 
Toho budeme využívat my, jelikož čteme z registrů Temperature value a ty jsou dva: **Temperature value most significant byte** a **Temperature value least significant byte**. Díky tomuto automatickému přičítaní můžeme číst z obou registrů zároveň.



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

### Popis jednotlivých bloků
#### clk_enable_gen
Blok, který generuje hodinový signál s frekvencí 200 kHz na výstupu ce_200kHz. Vzali jsme hodinový signál z naší FPGA desky o hodnotě 100 kHz a předělali ho na potřebných 200 kHz. 
Každých 500 náběžných hran z vstupu `clk` se vytvoří jeden puls na výstupu `ce`. 

#### i2c_master_cont
<img width="1314" height="553" alt="thermometer_top (1)" src="temp sensor - top documentation/txt pre tomasa/i2c_master_sim/i2c_sim.png" />
V tomto bloku probíhá hlavní I2C komunikace s teplotním senzorem. Někoho by mohlo zmást, proč přívádíme 100 MHz a 200kHz zároveň, když jsme si za účelem vytvoření našeho `ce` (clock enable) signálu vytvářeli celý blok. Signál ye vstupu `clk` o hodnotě 100 MHz slouží k vnitřní synchronizaci bloků **i2_master_cont** a **segcontrol**, aby vše probíhalo tak jak má. Zde ho zároveň i dělíme, stejně jako v bloku **clk_enable_gen** naším signálem z vstupního portu `ce`. Tento signál potom přetvoříme na `SCL`, který bude mít frekvenci 10 kHz. Signál SCL nám říká kdy čteme data z našeho senzoru. Nejdříve zahájíme komunikaci posláním start podmínky. `SDA` je permanentně připojené na pull-up rezistor, takže je vždy v 1 a naši komunikaci zahájíme posláním 0. Poté pošleme 7 bitovou adresu našeho slave(senzoru) a jestli z něj čteme(hodnota 1) nebo do něj zapisujeme (hodnota 0). Poté čekáme na ACK od senzoru a po ACK čteme už jednotlivé hodnoty hodnoty z registrů ve formátu, viz. odrážka Formát přijímaných dat. Komunikace končí NACK z naší strany. 

#### temp_conv
<img width="1314" height="553" alt="thermometer_top (1)" src="temp sensor - top documentation/txt pre tomasa/temp_conv_sim/temp_conv_sim.png" />
Tento blok nám slouží jako převod hodnoty z I2C do pro nás čitelné podoby, kterou pak následně pošle do bloku segcontrol. V tomto bloku nevyužíváme žádný clock, vše co přijde na vstup `temp_data` rovnou překládáme.
Číslo které dostaneme v binárním tvaru převádíme do klasického integer čísla, to potom vydělením 8 zmenšíme ze 16 bitů na 13 bitů, protože ty tři bity jsou nepotřebné a neobsahují hodnotu teploty. Poté se číslo vynásobí 625 a vydělí 100 a převede zpět na 16 bitové číslo a teplotu ve Fahrenheit. 

#### segcontrol
<img width="1314" height="553" alt="thermometer_top (1)" src="temp sensor - top documentation/txt pre tomasa/display_driver_sim/display_driver.png" />
Poslední modul zajišťuje zobrazení našich hodnot na 7 segmentových displejích. Nejdříve naši hodnotu převedeme na číslo, to potom dělením rozdělíme na stovky, desítky, jednotky, desetiny a setiny. Porty `seg` a `an` poté podle toho vyberou správný přirazený segment a ten potom rozsvití. Rozsvícení jednotlívých segmentu probíha tak, že vždy se rozsvítí jen jeden segment a tak se vystřídájí všechny segmenty tak rychle, že to lidské oko nepozná. 



### Schéma  

<img width="1314" height="553" alt="thermometer_top (1)" src="temp sensor - top documentation/thermometer_top.jpg" />

### Přidané soubory
[Plakát] (https://github.com/cryptonhd2004/i2c-thermometer/blob/main/temp%20sensor%20-%20top%20documentation/POSTER.png)

### Zdroje
* Constrain soubor pro Nexys A7 50T https://github.com/Digilent/digilent-xdc/blob/master/Nexys-A7-50T-Master.xdc
* Verilog inspirace: https://github.com/FPGADude/Digital-Design/tree/main/FPGA%20Projects/NexysA7_Temp_Sensor_I2C
* Datasheet pro naši desku Nexys A7 50T: https://digilent.com/reference/_media/reference/programmable-logic/nexys-a7/nexys-a7_rm.pdf
* Datasheet pro ADT7420: https://www.analog.com/media/en/technical-documentation/data-sheets/ADT7420.pdf
