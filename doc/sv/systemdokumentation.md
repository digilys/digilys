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

### Användare (User)

Datamodell för användarna i systemet. Används för autentisering av användare
m.h.a biblioteket `devise`.

#### Relationer

 * **Roll** - en användare kan ha 0 eller flera roller som ger användaren
   rättigheter i systemet.
 * **Grupp** - en användare kan vara associerad till 0 eller flera grupper.
   Lägger man till en grupp i en planering så får användaren automatiskt
   rättighet att arbeta i planeringen.
 * **Aktivitet** - en användare kan vara associerad till 0 eller flera
   aktiviteter.

### Elev (Student)

Datamodell för elever. Innehåller information om eleven, bl.a. namn och
personnummer. Eleven har även ett fritt fält där man kan ange godtycklig
information i formen namn/värde. Den godtyckliga informationen är inte avsed att
aggregeras; vill man ha aggregerade värden kan man använda ett generellt test.

#### Relationer

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

### Planering (Suite)

En planering är den sammanhållande modellen för planeringar. Modellen kan vara
en mall, se Mallar nedan för beskrivning.

#### Relationer

 * **Deltagare** - en planering har 0 eller flera deltagare.
 * **Test** - en planering har 0 eller flera tester.
 * **Möte** - en planering har 0 eller flera möten.
 * **Aktiviteter** - en planering har 0 eller flera aktiviteter.

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

 * **Planering** - ett test tillhör en planering, om det är av typen Planering.
 * **Resultat** - ett test har 0 eller flera resultat.

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

## Användarrättigheter

Beroende på vilken roll en användare har så har den olika rättigheter i
systemet. För auktoriseringen av användare används `cancan`.

Det finns följande roller i systemet:

 * **Administratör** - har fulla rättigheter i systemet, kan göra allt.
 * **Superuser** - har rättighet att skapa planeringar och tillhörande
   information, men kan inte påverka grunddata i systemet.
 * **Normal användare** - kan bara hantera de delar av systemet de har
   tilldelats rättigheter till, t.ex. specifika planeringar.

För exakt definition av rättigheterna i systemet hänvisas till
`Ability`-modellerna samt dokumentationen för `cancan`.

