twirror.rb
==========

Ein Tweet-Archivierungstool, basierend auf Ruby und dem Sinatra-Framework.

Anders als andere Archivierungstools setzt Twirror den Fokus darauf, alle Tweets, die ein User sehen konnte, zu sichern. Es werden also nicht nur eines Users Tweets gesichert, sondern auch die Tweets, die er in seiner 
Teimline zu sehen bekam (Tweets von Freunden und so).

Installation
------------
Man benötigt eine Installation von Ruby, Rubygems und (zum Anzaigen der Daten) Sinatra. Dies wird als gegeben angesehen.

* Man lade die Daten herunter und packe sie in einen Ordner.
* Man braucht eine Tabelle in einer MySQL-Datenbank. Das Schema zur Erstellung der Tabelle ist in db.schema.sql zu finden.
* Man kopiert config.yml.example zu config.yml und ändert dort die Zugangsdaten zur soeben erstellten MySQL-Datenbank.
* Man erzeugt einen Twitter App Key sowie Zugangskeys für seinen Account. Diese kommen dann ebenfalls in die config.yml.

Zum Updaten der Daten rufe man `twirror.rb` mit dem Parameter `-u` (wie "update") auf. Sinnvollerweise per Cron, damit dies automatisch und regelmäßig passiert.

`twirror_interface.rb` enthält eine (derzeit noch rudimentäre) Sinatra-App, um die ganzen Tweets durchsuchen zu können und so.
