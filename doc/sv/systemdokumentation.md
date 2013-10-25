# DigiLys - Systemdokumentation

Följande dokument är en övergripande systemdokumentation över DigiLys. I
dokumentet beskrivs arbetsflödet samt datamodellerna och dess relationer.
Specifika tekniska detaljer om modellerna och relationerna anges endast där det
krävs för att klargöra syftet, i övrigt hänvisas till modellerna och
enhetstesterna för teknisk information samt dokumentation för de bibliotek som
används i applikationen.

## Arbetsflöde

Det primära arbetsflödet kan delas in i tre delar: grundinformation, planering
samt genomförande.

### Grundinformation

Grundinformationen i systemet är oberoende av de enskilda planeringarna och
innefattar följande information:

 * Användare av systemet
 * Elever
 * Elevers grunddata (kan anges fritt i applikationen)
 * Grupperingar av elever (ex skola, klass)

Denna information anges oberoende av planeringar och finns att tillgå för alla
planeringar som en elev/användare är del av.

Grundinformationen lämpar sig väl att importeras från andra system.

### Planering

Planeringar i systemet utgör grunden för arbetsmetodiken att utvärdera eleverna.
En planering innefattar följande information:

 * Vilka elever det gäller
 * Vilka pedagoger som är inblandade
 * Vilka tester som skall göras
 * Vilka utvärderingsmöten som skall genomföras

En planering kan skapas innan själva utvärderingsarbetet inleds, och kan utökas
under arbetets gång med all typ av information som kan associeras med en
planering.

Man kan skapa planeringar utifrån mallar. Mallar beskrivs i ett särskilt avsnitt
nedan.

### Genomförande

I genomförandet arbetar pedagogerna i systemet enligt följande flöde:

 1. Genomför planerade tester
 2. Mata in resultat för eleverna
 3. Genomför utvärderingsmöte
 4. Planera och ange aktiviteter som skall genomföras

Under tiden som genomförandet pågår ackumuleras information om eleverna, och man
kan utvärdera den samlat i applikationen.

## Primära modeller och relationer

Relationerna mellan de primära modellerna ser ut som följer:

![Modeller och relationer](er.png)

Nedan beskrivs modellerna och dess relationer mer i detalj.

### Instanser (Instance)

Instanser är möjligheten att sätta upp separata virtuella applikationer inuti
applikationen. De kan användas för att bl.a. se till att de som arbetar i
applikationen bara har kan se relevant data.

#### Relationer

 * **Elev** - en elev måste tillhöra en instans.
 * **Grupp** - en grupp måste tillhöra en instans.
 * **Planering** - en planering måste tillhöra en instans.
 * **Test** - ett test måste tillhöra en instans, om det inte är ett test som
   tillhör en planering.

Förutom dessa direkta relationer så är alla modeller som tillhör ovan nämnda
modeller indirekt associerade med instanser.

### Användare (User)

Datamodell för användarna i systemet. Används för autentisering av användare
m.h.a biblioteket `devise`.

#### Relationer

 * **Roll** - en användare kan ha 0 eller flera roller som ger användaren
   rättigheter i systemet.
 * **Grupp** - en användare kan vara associerad till 0 eller flera grupper.
   Lägger man till en grupp i en planering så får användaren automatiskt
   rättighet att arbeta i planeringen.
 * **Test** - en användare kan vara associerad till 0 eller flera test. Används
   för att markera vilka som är ansvariga för ett test i en planering.
 * **Aktivitet** - en användare kan vara associerad till 0 eller flera
   aktiviteter.

Förutom dessa direkta relationer så finns även relationer till modeller via
roller som användaren har:

 * **Instanser** - en användare kan tillhöra (ha rättigheter på) 1 eller flera
   instanser.
 * **Planering** - en användare kan tillhöra (ha rättigheter på) 0 eller flera
   planeringar.

Se beskrivningen av roller nedan för mer detaljer om roller.

### Elev (Student)

Datamodell för elever. Innehåller information om eleven, bl.a. namn och
personnummer. Eleven har även ett fritt fält där man kan ange godtycklig
information i formen namn/värde. Den godtyckliga informationen är inte avsedd
att aggregeras; vill man ha aggregerade värden kan man använda ett generellt
test.

#### Relationer

 * **Instans** - en elev måste tillhöra en instans.
 * **Grupp** - en elev kan tillhöra 0 eller flera grupper. När grupper
   associeras med t.ex. planeringar så blir gruppens elever automatisk
   associerade med planeringen.
 * **Deltagare** - en elev kan vara en deltagare i en planering. Se
   beskrivningen av en deltagare nedan.
 * **Resultat** - en elev kan ha ett resultat på ett test.
 * **Aktivitet** - en elev kan tillhöra 0 eller flera aktiviteter.

### Grupp (Group)

Datamodell för gruppering av elever. Gruppen är ett flexibelt sätt att
representera exempelvis skolor/klasser/årskurser. Grupperna kan ordnas
hierarkiskt för att skapa strukturen skola-&gt;klasser.

#### Relationer

 * **Instans** - en grupp måste tillhöra en instans.
 * **Grupp** - en grupp kan tillhöra en annan grupp, och således utgöra en del
   av en hierarki.
 * **Elev** - en grupp kan ha 0 eller flera elever. Vanligtvis om gruppen
   associeras med någon annan modell så blir även eleverna associerade med
   modellen.
 * **Deltagare** - en grupp kan vara associerad med en deltagare i en planering.
   Se beskrivningen av en deltagare nedan.
 * **Aktivitet** - en grupp kan tillhöra 0 eller flera aktiviteter.

### Deltagare (Participant)

En deltagare är en koppling mellan elever och planeringar. Anledningen till att
deltagaren är en egen modell är att man kan välja att lägga till deltagare på
olika sätt i en planering, antingen genom att lägga till en enskild elev eller
genom att lägga till en grupp. Det krävs spårbarhet i hur eleven lades till,
eftersom det t.ex. ska fungera så att om man väljer att ta bort en grupp från
en planering så ska alla elever som lades till från den gruppen också tas bort.

#### Relationer

 * **Elev** - en deltagare tillhör alltid en elev.
 * **Planering** - en deltagare tillhör alltid en planering.
 * **Grupp** - en deltagare kan tillhöra en grupp.
 * **Test** - en deltagare kan tillhöra 0 eller flera test. Används för att bara
   utföra test för vissa elever i en planering.

### Planering (Suite)

En planering är den sammanhållande modellen för planeringar. Modellen kan vara
en mall, se Mallar nedan för beskrivning.

#### Relationer

 * **Instans** - en planering måste tillhöra en instans.
 * **Deltagare** - en planering har 0 eller flera deltagare.
 * **Test** - en planering har 0 eller flera tester.
 * **Möte** - en planering har 0 eller flera möten.
 * **Aktiviteter** - en planering har 0 eller flera aktiviteter.

Förutom dessa direkta associationer så finns även en eller flera **Användare**
associerade till planeringen via roller.

### Test (Evaluation)

Ett test representerar de tester som görs av pedagogerna. Den innehåller
information om maximalt resultat, färg- och stanine-intervaller, samt
extrainformation om hur resultatet ska presenteras.

För att enklare kunna aggregera data så anges alla testresultat som numeriska
värden, även t.ex. betyg A-F. Till testet hör information om hur de olika
numeriska värdena ska presenteras, t.ex. A-F för betyg.

Ett test kan vara av olika typer:

 * Generiskt - ett generiskt test som inte är associerat med en planering.
   Generiska tester används för att bygga upp aggregerbar data för eleven, och
   kan t.ex. användas för att lagra betyg som man sedan kan färgkoda.
 * Mall - testmallar, se Mallar nedan.
 * Planering - ett test som tillhör en planering.

Ett test kan även ha olika typer för värden. I dagsläget finns följande
värdetyper:

 * Numeriskt - testernas resultat är normala numeriska värden.
 * Booleskt - testernas resultat är av formen ja/nej (sant/falskt).
 * Betyg - testernas resultat är ett betyg A-F.

Man kan välja att associera ett test bara med ett visst kön. Det gör att
systemet bara presenterar deltagare av ett visst kön när man skall mata in
resultatet.

#### Relationer

 * **Instans** - ett test måste tillhöra en instans, om det inte är ett test som
   tillhör en planering.
 * **Planering** - ett test tillhör en planering, om det är av typen Planering.
 * **Resultat** - ett test har 0 eller flera resultat.
 * **Användare** - ett test har 0 eller flera användare. Används för att markera
   ansvarig för testet.
 * **Deltagare** - ett test kan vara direkt associerad med 0 eller flera
   deltagare. Det gör att endast de direkt associerade behöver rapportera
   resultat på testet.

### Resultat (Result)

Ett resultat är det faktiska resultatet som en elev har presterat på ett test.
Det anges som ett numeriskt värde, och modellen innehåller även information om
vilken färgkodning och stanine-värde det resulterat i.

#### Relationer

 * **Test** - ett resultat tillhör ett test.
 * **Elev** - ett resultat tillhör en elev.

### Möte (Meeting)

Modellen för ett möte utgör en tidpunkt, en agenda och möjlighet att rapportera
att mötet är genomfört och vad det gav för resultat. Utifrån mötet anger man ett
antal aktiviteter som skall genomföras.

#### Relationer

 * **Planering** - ett möte tillhör en planering.
 * **Aktivitet** - ett genomfört möte har 0 eller flera planerade aktiviteter
   som resultat.

### Aktivitet (Activity)

En aktivitet är en planerad aktivitet som efter ett möte har bestämts ska
genomföras. Aktiviteten kan vara av två typer: insatser och frågeställningar.
Rent tekniskt är det ingen skillnad på dessa, det är endast presentationen som
är annorlunda.

#### Relationer

 * **Planering** - aktiviteten tillhör en planering.
 * **Möte** - aktiviteten tillhör ett möte, det möte där aktiviteten bestämdes.
 * **Elev** - aktiviteten har 0 eller flera elever, de elever aktiviteten
   gäller.
 * **Grupp** - aktiviteten har 0 eller flera grupper. Används för att kunna
   associera en aktivitet snabbt med en viss grupp.
 * **Användare** - aktiviteten har 0 eller flera användare. Det är de användare
   som skall utföra aktiviteten.

### Anpassning (Setting)

En anpassning är en polymorfisk modell där någonting anpassningsbart
(customizable) kan anpassas av någonting (customizer). Syftet med modellen är
att ha en generell datamodell där man kan associera anpassningsdata till
någonting där det är relevant att veta vem eller vad som gjorde anpassningen.

Exempelvis används anpassningen till att spara en specifik användares tillstånd
på färgkartan så att man får samma utseende om man loggar in från en annan
dator.

#### Relationer

 * **Customizable** - anpassningen måste tillhöra det som den anpassar.
 * **Customizer** - anpassningen måste tillhöra den som har gjort anpassningen.

### Tabelltillstånd (TableState)

Ett tabelltillstånd är en polymorfisk modell för att spara och namnge
tillståndet på en tabell. Används för att spara ner JSON-strukturen som
representera tillståndet för en DataTables-tabell så att man kan ladda olika
utseenden på tabellen.

#### Relationer

 * **Base** - tabelltillståndet måste tillhöra den modell vars tabell den har
   sparat utseendet för.

## Mallar

Mallar är ett sätt att bygga upp tester och planeringar så att man kan
återanvända dessa. Exempelvis kan man bygga upp planeringsmallar för en viss
årskurs och sedan används den för att skapa enskilda planeringar för klasser.

Det finns två typer av mallar, tester och planeringar.

### Testmallar

Testmallar är i praktiken fristående tester med definierade resultatintervall.
När man skapar ett nytt test, oavsett vilken typ det är, så kan man välja att
använda värden från en testmall. Om man väljer detta så kopieras nödvändig
information från mallen så att man endast behöver ange information som är
specifik för den aktuella planeringen.

Mallen utgör endast basen för ett test. Väljer man att ändra en mall så påverkas
inte de tester som skapats från mallen, och mallen ändras inte heller om man
ändrar testerna.

### Planeringsmallar

Planeringsmallar är i praktiken planeringar utan exempelvis information om
datum/tider för tester och möten samt vilka som deltar i planeringen. När man
skapar en planeringsmall så kan man välja att lägga till ett antal tester och
möten som planeringen innehåller.

När man skapar en planering kan man välja att använda en mall som bas för
planeringen. Gör man detta kopieras informationen från mallen, inklusive tester
och möten till planeringen. Det innebär att man endast behöver ange sådant som
är specifikt för en planering när man skapar den, t.ex. datum för tester och
möten.

Mallen utgör endast basen för planeringen. Väljer man att ändra en mall så
påverkas inte de planeringar som skapats från mallen, och mallen ändras inte
heller om man ändrar planeringarna.

## Övriga modeller

Följande modeller är enkla modeller som inte direkt påverkar det primära
arbetsflödet.

### Roll (Role)

Modell för att representera olika roller en användare kan ha. Används av
biblioteket `rolify` och tillsammans med `cancan` så ger den användare olika
rättigheter i systemet.

### Instruktion (Instruction)

Instruktioner används för att administratörer i systemet ska kunna bygga in
hjälpfunktionalitet i applikationen. Modellen är primärt gjord för att bädda in
instruktionsfilmer, och är kopplade till sökvägar i applikationen.

### Taggtabeller

Generisk taggning av modeller m.h.a. `acts-as-taggable-on`.

## Serialiserad data

Det finns flera fall i modellerna där behovet av en flexibel typ av datastruktur
behöver användas, men där man inte behöver göra utsökningar baserat på
innehållet i datastrukturen. I dessa fall har valet gjorts att serialisera
JSON-data istället för att bygga komplexa generiska tabeller i databasen för att
tillgodose strukturen. Det gör att man har en kraftfull datastruktur att arbeta
med i koden, samtidigt som man inte behöver göra stora joins i databasen för att
hämta ut data.

Valet är även framtidssäkrat: skulle behovet finnas att man behöver göra
utsökningar av den data som finns i serialiserade fält så finns det två vägar
att gå. Antingen så bygger man en tabellstruktur och sedan sparar ner den
befintliga serialiserade datan i tabellerna istället, eller så aktiverar man
JSON-indexeringen i PostgreSQL.

För specifika detaljer om exakt vilka fält som är serialiserade, se modellerna
samt dess spec:ar.

### Exempel

De olika representationerna av hur värden mappas mot färger skiljer sig beroende
på vilken typ av tester det är. Exempelvis så har ett booleskt test följande
mappning:

    ja:  <färg>
    nej: <färg>

medan betyg har följande mappning:

    A: <färg>
    B: <färg>
    C: <färg>
    D: <färg>
    E: <färg>
    F: <färg>

I båda fallen kan färgerna komma i vilken ordning som helst.

För att göra det så enkelt och flexibelt används en JSON-struktur där man har
själva resultatet som nyckel och färgen som värde, så att man enkelt kan hämta
ut vilken färg det är.

## Användarrättigheter

Beroende på vilken roll en användare har så har den olika rättigheter i
systemet. För auktoriseringen av användare används `cancan`.

Det finns följande globala roller i systemet:

 * **Administratör** - har fulla rättigheter i systemet, kan göra allt.
 * **Superuser** - har rättighet att skapa planeringar och tillhörande
   information, men kan inte påverka grunddata i systemet.
 * **Normal användare** - kan bara hantera de delar av systemet de har
   tilldelats rättigheter till, t.ex. specifika planeringar.

Förutom dessa roller finns även specifika roller på varje specifik planering:

 * **Förvaltare** - har fulla rättigheter på planeringen, kan göra allt inom
   planeringen. Tilldelas till den som skapar planeringen.
 * **Bidragsgivare** - kan göra allt i en planering förutom att ändra eller ta
   bort själva planeringsobjektet. Läggs till av förvaltare efter att
   planeringen har skapats.

För exakt definition av rättigheterna i systemet hänvisas till
`Ability`-modellerna samt dokumentationen för `cancan`.

