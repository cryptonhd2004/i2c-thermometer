# I2C Thermometer implementation

### Členové Týmu

* Adam Solovic
* Tomáš Střelec
* David Šindelář

### Abstrakt


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

### Zdroje
Constrain soubor pro Nexys A7 50T https://github.com/Digilent/digilent-xdc/blob/master/Nexys-A7-50T-Master.xdc
Verilog inspirace: https://github.com/FPGADude/Digital-Design/tree/main/FPGA%20Projects/NexysA7_Temp_Sensor_I2C
Datasheet: https://www.analog.com/media/en/technical-documentation/data-sheets/ADT7420.pdf
