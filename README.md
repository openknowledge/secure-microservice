# Secured Microservices mit MicroProfile und Keycloak
Euer Service soll nur authentifizierte Anfragen beantworten oder nur Aufträge von vertrauenswürdiger Stelle annehmen?
– Was in gängigen Monolithen mit „einfachen“ Zugangsbeschränkungen gelöst werden konnte, muss im Microservice Umfeld
anders und feingranularer gedacht werden. Das neue MicroProfile 3.3 bietet hier Ansätze zum Thema verteile Sicherheit
von Microservices, die wir Dir im Folgenden praktisch näherbringen wollen.

Bei diesem Projekt handelt es sich um das Beispiel für unseren gleichnahmigen
 [Blog-Eintrag](https://www.openknowledge.de/secured-microservices-mit-microprofile-und-keycloak/).

### Starten der Beispiel-Anwendung
Folgende Software wird auf eurem System erwartet: Java 11, Maven 3.6, Node, NPM und Docker (mit Docker-Compose). Nach
erfolgreichem Checkout aus diesem Repository kann die Anwendung einfach per "_start.sh_" oder "_start.bat_" gestartet
werden.

Das Skript wird zunächst die Anwendung mit Maven bauen, anschließend die nötigen Docker-Images bauen und zuletzt die
Anwendung über "docker-compose" starten.

### URLs der Anwendung
| URL | Anwendung | Zugangsdaten<br/>(Nutzername -:- Passwort) |
| --- | --- | --- |
| http://localhost:8282/auth | Keycloak Console | admin -:- keycloak |
| http://localhost:8200/ | MailCatcher | none |
| http://localhost:8000/ | Webanwendung	| test.user@domain.tld -:- Test1234<br/>test.admin@domain.tld -:- Test1234 | 
| http://localhost:8080/secure/message/user	| GET - Schnittstelle für User-Message | Token: erforderlich<br/>Rolle: USER |
| http://localhost:8080/secure/message/admin | GET – Schnittstelle für Admin-Message | Token: erforderlich<br/>Rolle: ADMIN |
| http://localhost:8080/secure/openapi-ui | Visualisierung der openapi Doku	| none |

### Aufbau des Beispiels
Das Beispiel besteht aus einem sich selbst konfigurierenden Keycloak-Server, einer einfachen React-Webanwendung und
einem Microservice mit zwei rollenbasierten Schnittstellen.

#### Keycloak unter der Haube
Um das Beispiel einfach zu halten, wird die Konfiguration des Keycloak-Servers per Skript beim Start der Anwendung
durchgeführt. Im Folgenden wird kurz beschrieben, welche Schritte dabei durchlaufen werden und warum. Wer selbst einen
Blick riskieren möchte, findet die Keycloak-Oberfläche unter http://localhost:8282/auth und kann sich mit dem
Nutzername „admin“ und dem Passwort „keycloak“ anmelden:

##### Schritt 1: Realm anlegen und konfigurieren
Der Realm im Keycloak beschreibt den Nutzerkreis von Personen, deren Zugriffe verwaltet werden. Zusätzlich werden alle
„zentralen“ Einstellungen für diesen Nutzerkreis verwaltet. Dazu gehören folgende Einstellungen:

Die Login-Masken Konfiguration, ob es erlaubt ist, dass der Nutzer sich selbst am Keycloak registrieren kann oder ob
die E-Mail-Adresse durch den Keycloak verifiziert werden soll. Die Mail-Server Konfiguration, über die der
Keycloak-Server E-Mails versenden kann.

##### Schritt 2: Rollen anlegen
In diesem Beispiel werden die Keycloak Realm-Rollen dazu genutzt die Nutzerkreise für die einzelnen Clients
einzuschränken. Dazu wird eine Rolle mit demselben Namen, wie der Client erzeigt („OK-REACT-DEMO-WEBAPP“).

##### Schritt 3: Authentication konfigurieren
Um die Realm-Rollen-Zuordnung bei der Anmeldung zu berücksichtigen wird ein neuer Anmeldeablauf konfiguriert, der
neben der Abfrage des Nutzernamen und des Passworts zusätzlich die erforderliche Rollenzuordnung prüft.

Dazu wurde eine Extension für den Keycloak-Server verwendet, die mit der Überprüfung der Rollen betraut ist, aber
durch einen angepassten Anmeldeablauf eingebunden werden muss. Die Extension ist im Beispiel enthalten und darf
gerne übernommen werden.

![](readme/images/Keycloak%20-%20Authentication%20settings.png?raw=true)

##### Schritt 4: Client anlegen und konfigurieren
Ein „Client“ stellt die Konfiguration für eine angebundene Webanwendung da, dabei empfiehlt es sich, für jede
Anwendung einen eigenen Client anzulegen. Neben Einstellungen für valide Redirect-URLs, Web-Origins oder dem
Access-Type „public“ wird auch der zuvor erstellte Authentication-Flow gewählt.

![](readme/images/Keycloak%20-%20Client%20settings.png?raw=true)

In unserem Beispiel werden die Client-Rollen genutzt, um die System-Rollen des Nutzers zu realisieren
(„USER“ und „ADMIN“). Um den Token für das MicroProfile richtig zu konfigurieren wird der Scope „microprofile-jwt“
als Default benötigt. Über den erstellten Token Mapper werden die Client-Rollen in den Token für das Feld „groups“
übernommen.

![](readme/images/Keycloak%20-%20Client%20-%20Client%20Scopes%20settings.png?raw=true)

Die zuvor beschriebene nötige Konfiguration des Keycloak-Clients (Teil der Webanwendung) kann dem Reiter
„Installation“ entnommen werden (Format: „Keycloak OIDC JSON“). Der Download wurde in diesem Beispiel in das
Verzeichnis der Anwendung gelegt („keycloak.json“).

##### Schritt 5: Nutzer anlegen und konfigurieren
Für die Beispiel-Anwendung wurden zwei Nutzer angelegt und die entsprechende Gruppenzuordnung vorgenommen.
Zusätzlich wurde das Passwort auf den Wert „Test1234“ gesetzt.

#### Webanwendung unter der Haube
Die im Beispiel enthaltene Webanwendung ist unter der URL http://localhost:8000 erreichbar und öffnet sich, ohne
die Anmeldung in Richtung Keycloak-Server zu veranlassen. Dieses Szenario wurde gewählt, um dem Anwender seinen
aktuellen Zustand zu visualisieren.

![](readme/images/Webanwendung%20-%20Start-Screen.png?raw=true)

Durch den Klick auf den Login-Knopf wird die Anmeldung in Richtung Keycloak-Server veranlasst.

![](readme/images/Webanwendung%20-%20Redirect%20Keycloak%20Login.png?raw=true)

Nach erfolgreicher Anmeldung des Nutzers leitet der Keycloak-Server den Nutzer mit gültigem Token wieder zur
Anwendung zurück.

![](readme/images/Webanwendung%20-%20After%20Login.png?raw=true)

Der Anmeldetoken verliert nach einer gewissen Zeit seine Gültigkeit und muss erneuert werden. In der Demo-Anwendung
wird dafür der Knopf „Refresh“ geklickt.

![](readme/images/Webanwendung%20-%20Accesstoken%20expired.png?raw=true)

Abhängig von den Nutzer-Rechten und dem Schalter „Respect Roles“ können die Knöpfe „Access as USER“ oder
„Access as ADMIN“ geklickt werden. Durch den Klick wird eine der beiden Schnittstellen des im Hintergrund laufende
Microservice angefragt. Ist der Nutzer berechtigt die Schnittstelle zu nutzen, wird eine entsprechende Antwort
gesendet. Andernfalls kann entweder der Knopf nicht geklickt werden oder die Schnittstelle antwortet mit der
Nachricht, dass der Nutzer nicht berechtigt ist die Schnittstelle zu nutzen.

#### Microservice unter der Haube
Der Microservice verfügt über keine Oberfläche, so dass die Anfragen und Antworten nicht visualisiert werden können.
Allerdings werden alle Anfragen und Antworten in das Log-File geschrieben. Unter der URL
http://localhost:8080/secure/openapi-ui kann allerdings die Visualisierung der openapi.yaml angeschaut werden.

![](readme/images/Microservice%20-%20OpenApi%20UI.png?raw=true)