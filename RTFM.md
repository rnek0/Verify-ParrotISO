# Pourquoi verifier les checksums?

__Intégrité__ : De manière générale, l'intégrité des données désigne l'état de données qui, lors de leur traitement, de leur conservation ou de leur transmission, ne subissent aucune altération ou destruction volontaire ou accidentelle, et conservent un format permettant leur utilisation. L'intégrité des données comprend quatre éléments : l'intégralité, la précision, l'exactitude/authenticité et la validité. Voir sur [wikipédia](https://fr.wikipedia.org/wiki/Int%C3%A9grit%C3%A9_(cryptographie))

__Somme de contrôle__ (checksum en anglais): est une courte séquence de données numériques calculée à partir d'un bloc de données plus important (par exemple un fichier ou un message) permettant de vérifier, avec une très haute probabilité, que l'__intégrité__ de ce bloc a été préservée lors d'une opération de copie, stockage ou transmission. On parle aussi parfois [d'empreinte numérique](https://fr.wikipedia.org/wiki/Empreinte_num%C3%A9rique). Pour l'utilisateur final, les sommes de contrôle se présentent typiquement sous la forme de nombres au format hexadécimal, voir [sha-512](https://fr.wikipedia.org/wiki/SHA-2#SHA-512). L'utilisation d'une somme de contrôle est une forme de contrôle par redondance.

## Parrot déploie de nouvelles clés GPG !

Lire l'article sur <https://www.parrotsec.org/blog/2025-01-11-parrot-gpg-keys/>

## GnuPG

[GnuPG](https://fr.wikipedia.org/wiki/GNU_Privacy_Guard) est une implémentation complète et gratuite de la norme OpenPGP comme défini par [RFC4880](https://www.ietf.org/rfc/rfc4880.txt) (également connu sous le nom de PGP). GnuPG vous permet de crypter et signez vos données et vos communications ; il dispose d'une gestion de clés polyvalente système, ainsi que des modules d'accès pour toutes sortes de clés publiques répertoires. GnuPG, également connu sous le nom de GPG, est un outil de ligne de commande avec fonctionnalités pour une intégration facile avec d'autres applications. Une richesse de applications front-end et bibliothèques sont disponibles. GnuPG également fournit un support pour S/MIME et Secure Shell (ssh).

Depuis son introduction en 1997, GnuPG est [Logiciel libre](https://fr.wikipedia.org/wiki/Logiciel_libre) (ce qui signifie que il respecte votre liberté). Il peut être librement utilisé, modifié et distribué selon les termes de la Licence publique générale GNU .

La version actuelle de GnuPG est la 2.4.8. 

> Site web: <https://gnupg.org/>

---

Traduction de : <https://parrotsec.org/docs/configuration/hash-and-key-verification/> 

La plupart des gens — même les programmeurs— sont confus quant aux concepts de base sous-jacents aux signatures numériques. Par conséquent, la plupart des gens devraient lire cette section, même si elle semble triviale à première vue.

Les signatures numériques peuvent à la fois prouver l’authenticité et l’intégrité avec un degré raisonnable de certitude. L'authenticité garantit qu'un fichier donné a bien été créé par la personne qui l'a signé (c'est-à-dire qu'il n'a pas été falsifié par un tiers). L'intégrité garantit que le contenu du fichier n'a pas été altéré (c'est-à-dire qu'un tiers n'a pas modifié indétectablement son contenu en cours de route).

Les signatures numériques ne peuvent prouver aucune autre propriété (par exemple que le fichier signé n'est pas malveillant). Rien ne pourrait empêcher quelqu’un de signer un programme malveillant (et cela arrive de temps en temps dans la réalité).

Le fait est que nous devons décider à qui nous ferons confiance (par exemple Linus Torvalds, Microsoft ou le projet Parrot) et supposons que si un fichier donné a été signé par une partie de confiance, il ne doit pas être malveillant ou bogué par négligence. La décision de faire confiance ou non à une partie donnée dépasse le cadre des signatures numériques. C'est plutôt une décision sociologique et politique.

Une fois que nous décidons de faire confiance à certaines parties, les signatures numériques sont utiles, car elles nous permettent de limiter notre confiance uniquement aux quelques parties que nous choisissons et de ne pas nous soucier de toutes les mauvaises choses qui peuvent arriver entre nous et elles, par exemple les compromissions de serveur (parrotsec.org sera sûrement compromis un jour, alors ne faites pas aveuglément confiance à la version live de ce site), au personnel informatique malhonnête de la société d'hébergement, au personnel malhonnête des FAI, aux attaques Wi-Fi, etc.

En vérifiant tous les fichiers que nous téléchargeons et qui prétendent être rédigés par une partie en laquelle nous avons choisi de faire confiance, nous éliminons les inquiétudes concernant les mauvaises choses évoquées ci-dessus, car nous pouvons facilement détecter si des fichiers ont été falsifiés (et choisir ensuite de nous abstenir de les exécuter, de les installer ou de les ouvrir).

Toutefois, pour que les signatures numériques aient un sens, nous devons nous assurer que les clés publiques que nous utilisons pour la vérification des signatures sont bien celles d’origine. N'importe qui peut générer une paire de clés GPG qui prétend appartenir au “Parrot OS” mais bien sûr, seule la paire de clés que nous (c'est-à-dire l'équipe Parrot) avons générée est la légitime. La section suivante explique comment vérifier la validité des clés de signature ParrotOS dans le processus de vérification d'un ISO Parrot OS. Cependant, les mêmes principes généraux s'appliquent à tous les cas dans lesquels vous souhaiterez peut-être vérifier une signature PGP, comme la vérification des référentiels, et pas seulement des ISO.

