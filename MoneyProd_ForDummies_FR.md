<p align="center">
 <img src="images/moneyprod-logo.svg" alt="MoneyProd, Algorithmic Trading System" width="450">
</p>

<h3 align="center"><em>MoneyProd pour les Nuls</em></h3>
<h4 align="center">Le guide complet pour comprendre un systeme de trading autonome<br>sans doctorat en informatique</h4>

<p align="center">
 <strong>Auteur :</strong> <a href="https://linkedin.com/in/timothy-lokotar/">Timothy Lokotar</a> · <a href="https://www.moneyprod.com/">MoneyProd</a><br>
 <a href="https://www.moneyprod.com/">Dashboard en direct</a> · <a href="https://linkedin.com/in/timothy-lokotar/">LinkedIn</a>
</p>

---

> *On n'a pas besoin de comprendre le fonctionnement d'un moteur a combustion pour apprecier qu'une voiture va plus vite qu'un cheval. Mais si quelqu'un vous tend les cles d'une Formule 1 en disant "elle conduit toute seule," il serait peut-etre sage de jeter un oeil sous le capot.*
>
> *Ce document, c'est le capot, souleve.*

---

## Partie I : Vue d'ensemble

### Chapitre 1: Qu'est-ce que MoneyProd ?

![Vue d ensemble](images/dummies-big-picture.svg)

> **DANS CE CHAPITRE :**
> - Ce que le systeme fait, en francais simple
> - Pourquoi il existe
> - Comment il prend ses decisions

Il existe, quelque part entre New York et Tokyo, une machine qui ne dort jamais, ne doute jamais, et prend 120 decisions par semaine avec l'argent d'autrui. Voici comment elle raisonne.

Imaginez que vous engagiez 19 chercheurs, chacun expert dans un domaine different du monde financier. L'un observe ce que font les traders particuliers. Un autre lit les actualites. Un troisieme etudie le marche des options. Un quatrieme suit l'economie mondiale, marches boursiers, rendements obligataires, cours du petrole, de l'or.

Toutes les heures, les 19 chercheurs remettent leurs rapports. Un panel de 4 juges, chacun utilisant une methode d'analyse differente, examine les rapports et vote sur ce que le marche des devises va faire ensuite. Un gestionnaire des risques decide alors combien d'argent miser sur ce vote. Et un officier de securite verifie 9 systemes d'alarme independants pour s'assurer que rien de dangereux ne se passe.

L'ensemble du processus prend **168 secondes**. Moins de 3 minutes. Puis il se repete. Toutes les heures. Cinq jours par semaine. Sans intervention humaine.

Voila MoneyProd.

En termes techniques, c'est un **systeme de trading algorithmique entierement autonome** qui negocie 8 paires de devises (comme EUR/USD et USD/JPY) sur 8 comptes de courtage chez Interactive Brokers. Mais vous n'avez pas besoin de savoir ce qu'"algorithmique" signifie pour comprendre la suite de ce document.

> **ASTUCE :** MoneyProd fonctionne comme un employe extremement discipline qui ne dort jamais, ne ressent aucune emotion, et suit le meme processus de decision chaque heure. Il n'a pas d'intuitions. Il ne s'excite pas apres un gain ni ne deprime apres une perte. Il suit les donnees, point final.

Mais que se passe-t-il, exactement, dans ces 168 secondes ? Il se trouve qu'on peut faire tenir un monde entier dans moins de temps qu'il n'en faut pour faire cuire un oeuf.

---

### Chapitre 2: Le battement de coeur de 168 secondes

![Battement de coeur](images/dummies-heartbeat.svg)

> **DANS CE CHAPITRE :**
> - Ce qui se passe chaque heure
> - Le pipeline en langage courant
> - Pourquoi le timing est crucial

Il est 6h55 du matin a New York. Londres bat son plein, Tokyo ferme les yeux, et une horloge quelque part franchit la barre des 55 minutes. Ce tic-tac declenche tout.

Toutes les heures, a 55 minutes passees (6h55, 7h55, 8h55...), MoneyProd se reveille. Dans les 168 secondes qui suivent, il va :

| Etape | Temps | Ce qui se passe | L'analogie |
|-------|-------|----------------|-----------|
| **1. Collecter** | 0-56s | Aspirer 19 sources de donnees simultanement | 19 reporters appelant leurs sources |
| **2. Analyser** | 56-103s | Calculer 240 theories + entrainer les modeles ML | Des detectives analysant les preuves |
| **3. Prevoir** | 103-106s | Generer des previsions probabilistes a 4 jours | Des meteorologues dessinant des cartes |
| **4. Debattre** | 106-108s | 4 juges votent sur la direction du marche | Une deliberation de tribunal |
| **5. Dimensionner** | 108-109s | Calculer combien trader (8 couches de securite) | Le gestionnaire des risques disant "ce montant, pas plus" |
| **6. Executer** | 109-155s | Ecrire le fichier CSV qui controle 32 strategies | Envoyer les ordres au parquet |
| **7. Nettoyer** | 155-168s | Diagnostics, rapports, verifications | Le gardien verifiant chaque porte |

A la **155eme seconde**, le fichier CSV est ecrit. Ce fichier indique a MultiCharts (la plateforme de trading) quelles strategies parmi les 32 doivent etre actives, dans quelle direction (achat ou vente), et avec quelle taille de position. La plateforme le lit, et les ordres partent vers le courtier.

> **RETENIR :** Le systeme ne trade pas directement. Il ecrit un fichier qui *dit* a la plateforme de trading quoi faire. Pensez a un general qui redige des ordres que les soldats executent. Le general ne manie pas l'epee.

Les ordres sont rediges. Mais d'ou vient l'intelligence qui les nourrit ? Faisons connaissance avec les 19 chercheurs qui briefent l'etat-major.

---

### Chapitre 3: Les 19 chercheurs

![19 chercheurs](images/dummies-19-sources.svg)

> **DANS CE CHAPITRE :**
> - D'ou viennent les donnees
> - Ce que chaque source nous apprend
> - Pourquoi plus de sources, c'est mieux

MoneyProd collecte des donnees aupres de **19 sources differentes**, en parallele (toutes en meme temps) pour gagner du temps. C'est comme envoyer 19 reporters simultanement plutot que l'un apres l'autre :

**Sources de sentiment** (Que font les autres traders ?)
- 4 courtiers et plateformes rapportent quel pourcentage de leurs clients achete ou vend chaque paire de devises. Quand 80% des traders particuliers achetent, c'est souvent un signal contrarian, la foule a tendance a avoir tort aux extremes.

**Sources institutionnelles** (Que font les gros joueurs ?)
- La CFTC (une agence gouvernementale americaine) publie chaque semaine la position des grandes institutions. Quand les hedge funds sont massivement vendeurs sur l'Euro, cela signifie que l'argent serieux s'attend a une baisse de l'Euro.

**Actualites et calendrier** (Que se passe-t-il dans le monde ?)
- Un modele de traitement du langage naturel (FinBERT) lit les titres d'actualites financieres et les note comme positifs, negatifs ou neutres pour chaque devise. Le calendrier economique signale les evenements a venir (decisions de taux d'interet, rapports sur l'emploi) susceptibles de faire bouger les marches.

**Marche des options** (A quel point les gens ont-ils peur ?)
- Les prix des options revelent combien de volatilite le marche *anticipe*. Quand les prix des options sont anormalement eleves, le marche a peur. Quand ils sont bas, le marche est complaisant. MoneyProd classe chaque paire dans l'un des quatre "etats de peur", nous en parlerons au Chapitre 9.

**Marches de prediction** (Que pensent les parieurs ?)
- Des plateformes comme Kalshi et Polymarket permettent aux gens de parier sur des resultats specifiques (La Fed va-t-elle relever ses taux ? L'inflation va-t-elle depasser 3% ?). Ces prix sont remarquablement precis parce que les parieurs ont de l'argent reel en jeu.

**Donnees macro** (Que fait l'economie mondiale ?)
- C'est l'ajout le plus recent : 25 series de donnees provenant de Yahoo Finance et de la Reserve Federale, couvrant les marches boursiers (VIX, Nikkei, Eurostoxx), les rendements obligataires (US, UK, Australie, Allemagne, Italie), les matieres premieres (petrole, or, cuivre), et les indicateurs economiques (ISM Manufacturing, probabilite de recession).

> **ASTUCE :** Les 19 sources sont comme 19 fenetres differentes donnant sur la meme piece. Chaque fenetre montre un angle different. Aucune ne donne l'image complete, mais ensemble elles revelent des choses qu'aucune perspective isolee ne pourrait montrer.

Les chercheurs ont depose leurs rapports sur la table. Maintenant, quatre esprits tres differents vont se disputer le sens de tout cela.

---

## Partie II : Les quatre juges

### Chapitre 4: Le detective ML

> **DANS CE CHAPITRE :**
> - Comment fonctionne le modele de machine learning
> - L'analogie des "5 detectives dans une piece"
> - Pourquoi les ensembles battent les modeles uniques

![MoE Ensemble](images/moe-ensemble-v3.svg)

La plupart des systemes de trading ont un cerveau. Celui-ci en possede cinq, et ils se livrent une guerre silencieuse a chaque cycle.

Le modele ML (Machine Learning) est la **voix la plus forte** du systeme, il represente 50% de la decision finale. Mais ce n'est pas un modele unique. C'est 5 modeles travaillant ensemble dans une configuration appelee **Mixture of Experts** (melange d'experts).

**L'analogie du detective :**

Prenons une scene de crime. Vous faites venir 5 detectives, chacun forme a une technique d'investigation differente :

| Detective | Specialite | Vrai modele |
|-----------|-----------|------------|
| **Detective A** | Lit le langage corporel (indices sequentiels) | AdaBoost |
| **Detective X** | Analyse les preuves physiques (patterns de donnees) | XGBoost |
| **Detective L** | Lit des milliers de documents a toute vitesse | LightGBM |
| **Detective C** | Expert en categories de temoins | CatBoost |
| **Detective R** | Coordonne et choisit la meilleure theorie | Random Forest |

Chaque detective examine les memes preuves (134 points de donnees par paire de devises) et arrive a sa propre conclusion : le marche va monter, descendre, ou stagner.

Ensuite, le Detective R (le "Meta-Classificateur") examine les quatre conclusions et choisit celle qui a le plus de chances d'etre juste, en fonction de quel detective a ete le plus precis recemment et dans des situations similaires.

C'est pour cela que le modele ML s'appelle un "Melange d'Experts", ce n'est pas un cerveau, ce sont cinq cerveaux en competition, et le plus malin l'emporte.

> **DETAIL TECHNIQUE :** Les 134 features par paire proviennent des 19 sources de donnees : scores de sentiment, positionnement institutionnel, calculs de theories, mesures de volatilite, probabilites des marches de prediction et indicateurs macro. Le modele ML traite tout cela comme des "preuves" et classifie la direction de marche la plus probable.

Les detectives ont rendu leur verdict. Mais un autre juge demande la parole, et celui-ci ne s'interesse qu'aux probabilites et a ce que le temps fera dans quatre jours.

---

### Chapitre 5: Le meteorologue

![Meteorologue](images/dummies-weather-forecast.svg)

> **DANS CE CHAPITRE :**
> - Comment fonctionnent les previsions a 4 jours
> - Le concept de chaine de Markov (simplifie)
> - Pourquoi la probabilite bat la certitude

Dire ce qui s'est passe, tout le monde sait faire. Le vrai talent, c'est de dire ce qui va se passer, et a quel point on devrait y croire.

Le deuxieme juge (28% du vote) est un **previsionniste probabiliste a 4 jours**. Il ne predit pas ce qui *va* se passer, il predit la *probabilite* de differents resultats.

**L'analogie de la meteo :**

Un meteorologue ne dit pas "il pleuvra demain a 14h37." Il dit "il y a 70% de chances de pluie." C'est plus utile parce que cela vous dit *a quel point etre confiant*. 70% de chances de pluie signifie prenez un parapluie ; 95% signifie annulez le pique-nique.

Le modele de prevision utilise des **matrices de transition de Markov**, une facon elegante de dire "ce qui se passe ensuite depend de ce qui se passe maintenant." Si le marche est actuellement en tendance haussiere, la matrice de transition vous donne la probabilite qu'il continue a monter (disons 60%), qu'il inverse a la baisse (25%), ou qu'il stagne (15%).

> **ASTUCE :** La prevision contribue a 28% du vote final. Quand la prevision est fortement en accord avec le modele ML, la confiance augmente. Quand ils sont en desaccord, la confiance chute, et le systeme trade moins ou pas du tout. Le desaccord entre juges est traite comme un signal d'alerte, pas comme un defaut.

Deux juges se sont exprimes. Le troisieme se moque des statistiques et des matrices de transition. Il n'a qu'une seule question : la derniere fois qu'on a fait ca, est-ce qu'on a gagne ?

---

### Chapitre 6: L'agent d'apprentissage par renforcement

![Joueur de poker](images/dummies-poker-player.svg)

> **DANS CE CHAPITRE :**
> - Ce que signifie l'apprentissage par renforcement
> - L'analogie du "joueur de poker"
> - Pourquoi apprendre de ses erreurs compte

Le troisieme juge (12% du vote) est un **agent de Reinforcement Learning (RL)**, un modele qui apprend non pas a partir de donnees historiques, mais de ses propres *actions et de leurs consequences*.

**L'analogie du joueur de poker :**

Prenons un joueur de poker qui tient un tableau de bord mental : "Chaque fois que j'ai bluffe avec une petite paire en position tardive, j'ai perdu de l'argent. Chaque fois que j'ai relance avec deux grosses cartes quand la table etait prudente, j'ai gagne." Au fil de milliers de mains, le joueur developpe une intuition pour savoir quelles actions fonctionnent dans quelles situations.

L'agent RL fait exactement cela. Il a joue 6 832 "mains" (trades), enregistrant le resultat de chacune. Son "tableau de bord" (appele Q-table) associe chaque combinaison d'etat de marche + action a une recompense attendue.

> **RETENIR :** L'agent RL n'a que 12% du vote parce qu'il est encore jeune, 6 832 experiences, c'est beaucoup pour un humain mais relativement peu pour un algorithme d'apprentissage. A mesure qu'il accumule plus de donnees et que ses predictions s'averent precises, le systeme augmentera graduellement son poids de vote. C'est ce qu'on appelle la *confiance progressive*.

Trois juges ont delibere sur les details. Le quatrieme s'approche de la fenetre et contemple l'economie dans son ensemble.

---

### Chapitre 7: Le macro-economiste

> **DANS CE CHAPITRE :**
> - Ce que fait la couche macro
> - L'analogie du "systeme meteorologique mondial"
> - Comment les donnees cross-asset ameliorent les previsions FX

![Macro Oracle](images/macro-oracle.svg)

Le quatrieme juge (10% du vote) est le plus recent ajout : un **signal composite macro** qui regarde au-dela du marche des devises pour comprendre ce que l'economie mondiale dit sur la direction du FX.

**L'analogie du systeme meteorologique mondial :**

Les mouvements de devises ne se produisent pas dans le vide. Quand le marche boursier americain s'effondre, le yen japonais monte (c'est une devise "refuge"). Quand le prix du cuivre baisse, le dollar australien a tendance a baisser aussi (l'Australie exporte beaucoup de cuivre). Quand les rendements obligataires europeens montent, l'euro se renforce.

Le macro-economiste suit ces relations a travers **8 modeles factoriels specifiques a chaque paire**, un pour chaque paire de devises. Chaque modele surveille exactement 4 facteurs les plus pertinents pour cette paire :

| Paire | Ce qu'il surveille | Pourquoi |
|-------|-------------------|----------|
| **AUD/USD** | Ecart de taux AU-US, BHP (minerai de fer), Cuivre, VIX | L'Australie est un exportateur de matieres premieres |
| **USD/JPY** | Ecart de taux US-JP, Nikkei, ETF obligataire TLT, VIX | Le Japon est sensible aux taux US et au risque actions |
| **EUR/USD** | Ecart de taux DE-US, Eurostoxx, Or, VIX | L'Euro suit la croissance europeenne et les flux refuges |
| **GBP/USD** | Ecart de taux UK-US, FTSE, Cuivre, VIX | La Livre suit la croissance britannique et le risque mondial |

> **ASTUCE :** Le macro-economiste est la voix "vue d'ensemble" dans la piece. Pendant que le detective ML examine 134 petits indices, le macro-economiste prend du recul et dit : "Attendez, l'economie mondiale est en recession. Les devises de matieres premieres vont souffrir, peu importe ce que les donnees de sentiment disent." C'est cette perspective plus large qui justifie l'ajout du signal macro.

Les quatre juges ont vote. Mais avant qu'un seul centime ne bouge, la decision doit survivre a un parcours d'obstacles concu par un ingenieur profondement paranoiaque.

---

## Partie III : L'officier de securite

### Chapitre 8: Neuf systemes d'alarme

> **DANS CE CHAPITRE :**
> - Pourquoi la securite compte plus que les signaux
> - L'analogie du "sous-marin"
> - Ce que fait chacun des 9 boucliers

![Nine Shields](images/nine-shields-v3.svg)

En trading, ce qui vous tue n'est jamais le risque que vous surveilliez. C'est celui que vous aviez oublie de verifier.

MoneyProd dispose de **9 systemes de securite independants**, et ce n'est pas un hasard. C'est une philosophie de conception empruntee aux centrales nucleaires et aux sous-marins : la **defense en profondeur**.

**L'analogie du sous-marin :**

Un sous-marin possede plusieurs couches de coque, plusieurs systemes d'air, plusieurs systemes de communication et plusieurs systemes de propulsion de secours. Si l'un tombe en panne, les autres maintiennent l'equipage en vie. Aucune defaillance unique ne peut couler le bateau.

Les 9 boucliers de MoneyProd fonctionnent de la meme maniere. Chacun surveille un type de risque different. Aucun ne communique avec les autres (ainsi un bug dans l'un ne peut pas desactiver un autre). N'importe quel bouclier peut reduire ou arreter le trading *independamment*.

| Bouclier | Ce qu'il surveille | L'analogie |
|----------|-------------------|-----------|
| **1. Regime IV** | Le niveau de peur du marche des options | Le detecteur de fumee |
| **2. Coupe-circuit PnL** | Les limites de perte hebdomadaires | Le bouton d'arret d'urgence |
| **3. Penalite de crowding** | Trop de paris dans une seule direction | La regle "ne mettez pas tous vos oeufs dans le meme panier" |
| **4. Cross-validation TWS** | Sante de la connexion courtier | Le systeme de communication de secours |
| **5. Integrite des donnees** | Fraicheur des donnees (9 points de controle) | L'inspecteur qualite |
| **6. Sante CSI v2** | Performance individuelle des strategies | Le comite d'evaluation du personnel |
| **7. Vol Kill Switch** | Panique sur les marches mondiaux | Le systeme d'alerte tsunami |
| **8. Regime macro** | Phase du cycle economique | Les previsions meteo saisonnieres |
| **9. Garde RME** | Integrite de l'execution des ordres | Le controleur aerien |

> **ATTENTION :** Le moment le plus dangereux en trading, c'est quand tout semble fonctionner parfaitement. La complaisance tue. Les 9 boucliers sont concus pour attraper les problemes *avant* qu'ils ne deviennent catastrophiques, meme quand les operateurs humains ne verraient rien d'anormal.

Neuf boucliers, c'est meticuleux. Mais le premier merite un chapitre a lui seul, car il fait quelque chose qu'aucun systeme de securite n'oserait normalement : parfois, il dit au systeme de prendre *plus* de risque.

---

### Chapitre 9: Le quadrant de la peur

> **DANS CE CHAPITRE :**
> - Ce que signifie la volatilite implicite (simplement)
> - Les 4 etats de peur
> - Le concept du Cygne Blanc

![IV Regime](images/iv-regime-v3.svg)

L'un des systemes de securite les plus puissants est le **classificateur de regime IV**. Il repond a une question simple : *a quel point le marche a-t-il peur ?*

**L'analogie de l'assurance :**

Les primes d'assurance vous disent a quel point la compagnie d'assurance vous considere comme risque. Primes elevees = risque percu eleve. Le marche des options fonctionne de la meme facon : quand les traders paient plus cher pour les options (volatilite "implicite" plus elevee), ils anticipent des mouvements de prix plus importants.

MoneyProd compare ce que le marche *anticipe* (volatilite implicite) avec ce qui *s'est reellement passe* (volatilite realisee). Cette comparaison revele 4 etats :

| Etat | Ce que cela signifie | Analogie | Reponse du systeme |
|------|---------------------|----------|-------------------|
| **COMPLAISANT** | Vol attendue = vol reelle | Ciel degage, primes normales | Trader normalement |
| **PRICE** | Vol attendue >> vol reelle | Acheter une assurance inondation pendant la secheresse | Legere prudence (85%) |
| **APEURE** | Tout est eleve, hedging panique | Acheter TOUTES les assurances a N'IMPORTE quel prix | Reduire l'exposition (70%) |
| **SURPRISE** | Vol reelle > vol attendue | Une tempete frappant quand personne n'a achete d'assurance | *Augmenter* l'exposition (120%) |

L'etat SURPRISE est le plus fascinant. Il s'appelle **Le Cygne Blanc**, l'oppose du Cygne Noir de Nassim Taleb. La ou un Cygne Noir est une catastrophe que personne n'avait predite, un Cygne Blanc est une *opportunite* cachee a la vue de tous. Le marche bouge vite mais ne l'a pas encore compris. MoneyProd voit cela comme une chance d'augmenter l'exposition pendant que le marche s'ajuste.

*Le Cygne Blanc s'envole*, quand la peur est mal calibree, l'opportunite prend son envol.

> **RETENIR :** Le concept du Cygne Blanc est unique a MoneyProd. La plupart des systemes de trading reduisent leur exposition quand la volatilite augmente. MoneyProd demande *pourquoi* la volatilite a augmente. Si la reponse est "le marche des options n'a pas encore rattrape la realite," le systeme augmente son exposition, tradant contre la jauge de peur mal calibree du marche.

Le Cygne Blanc chasse l'opportunite cachee. Mais que faire quand le danger est reel, partout, et simultane ? C'est alors que la plus forte alarme du batiment se declenche.

---

### Chapitre 10: Le systeme d'alerte tsunami

![Alerte tsunami](images/dummies-tsunami-warning.svg)

> **DANS CE CHAPITRE :**
> - Ce que fait le vol kill switch
> - L'analogie des "stations meteorologiques multiples"
> - Quand le systeme s'arrete completement

Le **Kill Switch de Volatilite Cross-Asset** est le systeme de securite le plus puissant. Il surveille 4 mesures differentes de stress du marche simultanement :

1. **VIX**, Jauge de peur du marche boursier americain
2. **Volatilite implicite FX**, Peur specifique aux devises
3. **OVX**, Volatilite du marche petrolier
4. **Volatilite TLT**, Stress du marche obligataire

**L'analogie des stations meteorologiques multiples :**

Prenons 4 stations meteorologiques, chacune mesurant une chose differente : la vitesse du vent, la pression barometrique, la temperature de l'eau et l'activite sismique. Si une *seule* station montre des lectures extremes, vous emettez un avertissement. Si *plusieurs* stations montrent des lectures extremes simultanement, vous ordonnez une evacuation totale.

Le vol kill switch fonctionne de la meme facon. Il calcule un z-score (une mesure de "a quel point c'est inhabituel ?") pour chacune des 4 mesures de volatilite :

| Condition | Classification | Ce qui se passe |
|-----------|---------------|----------------|
| Tous les z-scores < 2.0 | **NORMAL** | Trader normalement (100%) |
| Un z-score > 2.0 | **ELEVE** | Reduire toutes les positions a 50% |
| Un z-score > 4.0 | **CRISE** | Arreter TOUT le trading (0%) |

Un z-score de 2.0 signifie "ce niveau de volatilite est plus extreme que 97.5% de l'annee ecoulee." Un z-score de 4.0 signifie "cela ne s'est presque jamais produit dans l'annee ecoulee." Quand le vol kill switch s'active, il prend le dessus sur tout, peu importe ce que disent les 4 juges, peu importe la confiance du modele ML, le systeme ne tradera pas.

> **ASTUCE :** Le vol kill switch n'a ete declenche que quelques fois depuis le deploiement. A chaque fois, les marches subissaient un veritable stress multi-actifs (comme une crise geopolitique ou une decision surprise de banque centrale). A chaque fois, reduire l'exposition etait la bonne decision.

Nous avons rencontre les chercheurs, les juges, et les gardiens. Mais qui sont, au juste, les 32 soldats qui executent les ordres ? Leur histoire d'origine vaut le detour.

---

## Partie IV : Comment les strategies sont nees

### Chapitre 11: La forge a strategies

![Concours de talents](images/dummies-talent-show.svg)

> **DANS CE CHAPITRE :**
> - Comment 10 millions de strategies sont devenues 32
> - L'analogie du "concours de talents"
> - Pourquoi la destruction est l'objectif

Et si l'on pouvait auditionner dix millions de candidats pour n'en garder que les 32 qu'aucune epreuve n'a reussi a briser ?

Les 32 strategies de trading que MoneyProd gere n'ont pas ete concues par un humain. Elles ont ete **decouvertes par une machine** a travers un processus qui a commence avec 10 millions de candidates aleatoires et en a detruit 99,99968%.

**Le plus long concours de talents au monde :**

Imaginez un concours de talents avec 10 millions de candidats. Mais ce n'est pas un concours ordinaire, il comporte **9 tours**, et chaque tour teste quelque chose de completement different :

| Tour | Test | Candidats restants |
|------|------|-------------------|
| 1 | Savez-vous performer ? (Evolution genetique) | 50 000 |
| 2 | Avec du bruit aleatoire ? (Monte Carlo) | 5 000 |
| 3 | Sur une scene differente ? (Walk-forward) | 500 |
| 4 | Avec un equipement legerement different ? (Parametres) | 150 |
| 5 | Dans un pays different ? (Multi-marche) | 80 |
| 6 | Avec des poids aux chevilles ? (Slippage) | 50 |
| 7 | Audition finale avec les juges les plus severes | **32** |

Chaque tour teste une *dimension differente* de competence. Un candidat qui a une belle voix (backtest profitable) mais qui ne peut pas chanter avec un micro different (sensibilite aux parametres) ou dans un lieu different (test multi-marche) est elimine.

### Les 32 survivants

Les strategies survivantes forment une equipe parfaitement equilibree :

- **16 acheteurs + 16 vendeurs** (quand les acheteurs perdent, les vendeurs gagnent)
- **16 suiveurs de tendance + 16 retour a la moyenne** (differentes competences pour differents marches)
- **4 par paire de devises** sur 8 paires
- **4 par compte** sur 8 comptes de courtage

> **RETENIR :** Les 32 strategies ne sont pas "intelligentes." Elles sont *simples*, chacune utilise au plus 2 regles pour entrer dans un trade. Leur puissance ne vient pas de la complexite mais du fait qu'elles ont survecu a un processus de selection incroyablement brutal. Elles sont comme des marathoniens : pas rapides grace a des chaussures speciales, mais rapides parce qu'ils ont survecu a un programme d'entrainement qui a detruit tous ceux qui n'etaient pas genuinement, constitutionnellement, irrevocablement faits pour la distance.

Les 32 survivantes savent *quoi* faire. Reste a decider combien d'argent mettre en jeu, et c'est la que la prudence devient un art.

---

## Partie V : La salle de controle

### Chapitre 12: La cascade de dimensionnement a 8 couches

> **DANS CE CHAPITRE :**
> - Comment le systeme decide la taille des trades
> - L'analogie des "8 ralentisseurs"
> - Pourquoi chaque couche ne peut que reduire, jamais augmenter

![Sizing Cascade](images/sizing-cascade-v3.svg)

Savoir ou aller ne represente que la moitie du probleme. L'autre moitie, celle qui separe les survivants des victimes, c'est de savoir combien miser.

Une fois que les 4 juges ont decide *quoi* trader (direction), le systeme doit decider *combien* trader. C'est sans doute plus important que la direction, une bonne direction avec un mauvais dimensionnement peut quand meme faire perdre de l'argent.

MoneyProd utilise une **cascade a 8 couches** ou chaque couche ne peut que reduire la taille de la position, jamais l'augmenter :

**L'analogie des 8 ralentisseurs :**

Prenons une rue avec 8 ralentisseurs. Vous demarrez a la vitesse maximale (taille de position maximale basee sur les capitaux propres du compte). Chaque ralentisseur peut vous freiner mais jamais vous accelerer :

| Ralentisseur | Ce qu'il verifie | Comment il vous freine |
|-------------|-----------------|----------------------|
| **1. Base d'equite** | Combien d'argent y a-t-il dans le compte ? | Fixe la vitesse maximale |
| **2. Echelle ATR** | A quel point cette paire est-elle volatile en ce moment ? | Plus lent en conditions volatiles |
| **3. Plafond de levier** | Utilisons-nous trop d'argent emprunte ? | Limite dure sur l'emprunt |
| **4. Critere de Kelly** | Quelle est la taille de pari mathematiquement optimale ? | Freine si l'avantage est mince |
| **5. Vol Kill Switch** | Le marche mondial est-il en crise ? | Peut vous arreter completement |
| **6. Regime macro** | Sommes-nous en recession ? | Plus lent en mauvaise economie |
| **7. Regime IV** | A quel point le marche des options a-t-il peur ? | Plus lent quand la peur est elevee |
| **8. Cygne Blanc** | Y a-t-il une opportunite cachee ? | Peut *legerement* accelerer (seul cas) |

> **ATTENTION :** La couche 5 (Vol Kill Switch) est la seule qui peut amener la position a **zero**, un arret complet. Les couches 6-7 reduisent mais ne bloquent jamais completement. La couche 8 (Cygne Blanc) est la seule qui peut legerement augmenter la taille, et uniquement dans le rare regime SURPRISE.

La cascade decide de la taille. Mais comment savoir si une strategie merite encore de trader ? Cela necessite une evaluation de performance, et ces strategies en subissent une toutes les heures.

---

### Chapitre 13: Le moniteur de sante des strategies

![Sante CSI](images/dummies-csi-health.svg)

> **DANS CE CHAPITRE :**
> - Comment fonctionne CSI v2
> - L'analogie de "l'evaluation de performance de l'employe"
> - Pourquoi les penalites graduees battent les interrupteurs marche/arret

Chacune des 32 strategies est surveillee par **CSI v2** (Composite Strategy Index), un systeme de notation de sante qui fonctionne comme une evaluation de performance :

| Score CSI | Evaluation | Ce qui se passe |
|-----------|-----------|----------------|
| 80-100 | Excellent | Taille de trading complete (100%) |
| 60-79 | Bon | Legerement reduit (75%) |
| 40-59 | En developpement | Demi-taille (50%) |
| 20-39 | A ameliorer | Quart de taille (25%) |
| 10-19 | En probation | Exposition minimale (10%) |
| 0-9 | Suspendu | Pas de trading (0%) |

> **ASTUCE :** L'approche graduee empeche un probleme courant dans les systemes de trading : bloquer definitivement une bonne strategie a cause d'une mauvaise semaine. Les marches passent par des cycles. Une strategie de suivi de tendance sous-performera dans les marches a range, mais cela ne signifie pas qu'elle est cassee. CSI v2 reduit l'exposition pendant les mauvaises periodes tout en preservant la possibilite de recuperation quand les conditions changent.

Les strategies individuelles sont surveillees. Mais qu'en est-il du monde au-dela du marche des devises ? Les monnaies ne bougent pas dans le vide, et le systeme le sait.

---

## Partie VI : La vue globale

### Chapitre 14: La couche macro (simplifiee)

> **DANS CE CHAPITRE :**
> - Pourquoi l'economie mondiale compte pour le trading de devises
> - Trois systemes de securite macro
> - L'analogie des "saisons"

La couche macro est la facon dont le systeme prend du recul par rapport a l'analyse detaillee des devises pour poser une question plus large : *Quel est l'etat du monde ?*

**L'analogie des saisons :**

On ne plante pas de tomates en decembre. De meme, on ne devrait pas trader de la meme maniere en recession economique qu'en expansion. La couche macro identifie la "saison economique" actuelle :

| Saison | Etat economique | Comment le systeme reagit |
|--------|----------------|--------------------------|
| **Printemps** (REPRISE) | L'economie rebondit | Trades legerement plus grands (+10%) |
| **Ete** (EXPANSION) | L'economie croit regulierement | Tailles de trade normales |
| **Automne** (EXPANSION TARDIVE) | Croissance ralentissant, risques s'accumulant | Trades legerement plus petits (-10%) |
| **Hiver** (RECESSION) | L'economie se contracte | Trades beaucoup plus petits (-40%) |

> **RETENIR :** Le regime macro change lentement, sur des mois, pas des heures. C'est par conception. Le systeme ne devrait pas paniquer a cause d'un seul mauvais rapport economique. Au lieu de cela, il ajuste lentement son appetit pour le risque a mesure que l'environnement economique evolue.

Le systeme trade, s'ajuste, s'adapte. Mais qui surveille le surveillant ? Il s'avere que MoneyProd ne se fait pas confiance a lui-meme non plus.

---

### Chapitre 15: La veille de nuit

> **DANS CE CHAPITRE :**
> - Comment le systeme se surveille lui-meme
> - L'analogie du "service de reanimation"
> - Alertes Discord et le prompt de diagnostic

Un systeme de trading incapable de detecter ses propres defaillances est une bombe a retardement. MoneyProd a ete construit par quelqu'un qui le sait.

**L'analogie du service de reanimation :**

Dans un service de reanimation, les patients sont connectes a des dizaines de moniteurs : rythme cardiaque, pression arterielle, niveaux d'oxygene, temperature. Une seule lecture anormale declenche une alerte. Plusieurs lectures anormales declenchent un code bleu.

MoneyProd se surveille avec la meme intensite :

- **17 sondes inline** (Stage 1 a POST) verifient la qualite des donnees au fur et a mesure qu'elles traversent le pipeline
- **9 noeuds de surveillance** verifient la fraicheur des donnees dans toutes les bases de donnees critiques
- **50+ controles diagnostiques** organises en 14 categories (donnees, ML, risque, execution, infrastructure, macro...)
- **Notifications Discord** se declenchent instantanement pour les evenements critiques (ordres bloques, fonds negatifs, activation du vol kill switch)

Quand la note du pipeline descend en dessous de A, le systeme genere automatiquement un **prompt de diagnostic**, un document structure qui decrit exactement ce qui s'est mal passe et comment le reparer. C'est le systeme qui *se diagnostique lui-meme*, comme une voiture qui imprime son propre manuel de reparation quand le voyant moteur s'allume.

> **ASTUCE :** Les systemes de surveillance sont plus complexes que les systemes de trading eux-memes. C'est delibere. En trading de production, le plus grand risque n'est pas un mauvais signal, c'est un systeme qui *pense* fonctionner correctement alors que ce n'est pas le cas.

Chercheurs, juges, gardiens, strategies, dimensionnement, surveillance. Il est temps de voir le tableau complet.

---

## Partie VII : Vue d'ensemble

### Chapitre 16: L'image complete

> **DANS CE CHAPITRE :**
> - Comment toutes les pieces s'emboitent
> - L'analogie de "l'orchestre"
> - Pourquoi le tout est superieur a la somme des parties

![Pipeline DAG](images/pipeline-dag-v3.svg)

Si vous etes arrive jusqu'ici, vous avez visite chaque departement du batiment. Sortez maintenant et regardez l'ensemble fonctionner.

**L'analogie de l'orchestre :**

MoneyProd est un orchestre. Les 19 sources de donnees sont les musiciens. Les 4 juges (ML, Prevision, RL, Macro) sont les chefs de section. Le resolveur de meta-signal est le chef d'orchestre. La cascade de dimensionnement a 8 couches est l'ingenieur du son. Et les 9 boucliers de securite sont les pompiers postes a chaque sortie.

Aucun musicien seul ne fait la musique. Aucun juge seul ne prend la decision. La puissance vient de la *coordination* de nombreuses voix independantes, chacune apportant une perspective differente, chacune contrainte par un systeme qui valorise la prudence plus que la confiance.

Le resultat :
- 19 sources de donnees, collectees toutes les heures
- 134 features par paire, 1 072 au total
- 4 intelligences concurrentes avec des cadres analytiques differents
- 8 couches de dimensionnement, chacune une contrainte
- 9 systemes de securite independants
- 32 strategies, chacune survivante de 10 millions de candidates
- 8 paires de devises sur 8 comptes de courtage

Le tout coordonne par un unique pipeline de 168 secondes qui se repete chaque heure, de maniere autonome, sans intervention humaine.

> **RETENIR :** Le systeme est concu pour etre *ennuyeux*. Ennuyeux, c'est bien. Les systemes de trading excitants explosent. MoneyProd vise a etre la machine la plus fiablement ininteressante de la piece, prenant de petites decisions bien reflechies, heure apres heure, jour apres jour, comme un metronome qui transforme les donnees en alpha.

---

### Chapitre 17: Questions frequemment posees

> **DANS CE CHAPITRE :**
> - Questions courantes, reponses simples
> - Idees fausses corrigees

Toute explication suscite de nouvelles questions. Voici celles que l'on pose le plus souvent.

**Q : Le systeme peut-il perdre de l'argent ?**
R : Oui. Le systeme a des trades perdants, des jours perdants et des semaines perdantes. Aucun systeme de trading ne gagne a chaque fois. L'objectif est de gagner *plus souvent* et *plus profitablement* qu'il ne perd sur des periodes plus longues. Les 9 boucliers de securite existent pour prevenir les pertes catastrophiques, pas toutes les pertes.

**Q : Que se passe-t-il si internet tombe en panne ?**
R : Le systeme surveille la connectivite aux deux instances IB Gateway. Si l'une des deux est injoignable, le pipeline s'interrompt avant de generer le moindre signal. Les positions existantes restent en place (protegees par leur propre logique de sortie dans MultiCharts), et le systeme reessaie au cycle horaire suivant.

**Q : Que se passe-t-il pendant un flash crash ?**
R : Le Vol Kill Switch surveille 4 mesures de volatilite independantes. Pendant un flash crash, au moins une (generalement le VIX) va depasser le seuil de z-score, declenchant le mode ELEVE ou CRISE. En mode CRISE, tout nouveau trading est arrete.

**Q : Pourquoi 32 strategies et pas 100 ?**
R : Le gauntlet a 9 etapes est calibre pour produire environ 32 survivantes sur 10 millions de candidates. Plus de strategies signifierait des seuils de qualite plus bas. Moins de strategies signifierait une diversification insuffisante. 32 offre l'equilibre optimal : 4 par paire, parfaitement equilibrees entre direction et style.

**Q : Le systeme a-t-il besoin d'un humain pour fonctionner ?**
R : Pour les operations quotidiennes, non. Le systeme est entierement autonome. Cependant, un humain surveille les alertes Discord, examine le rapport diagnostique hebdomadaire et prend des decisions strategiques sur la configuration du systeme. Pensez a une voiture autonome qui a toujours un humain sur le siege passager surveillant le tableau de bord.

---

### Glossaire

| Terme | En francais simple |
|-------|-------------------|
| **ATR** | Average True Range, combien une paire bouge typiquement en une barre |
| **CSV** | Comma-Separated Values, un fichier tableur simple |
| **CSI** | Composite Strategy Index, le score de sante de la strategie |
| **DLL** | Dynamic Link Library, un petit programme appele par la plateforme |
| **IV** | Implied Volatility, combien de mouvement le marche des options anticipe |
| **Kelly** | Un critere mathematique pour la taille de pari optimale |
| **MCPT** | MultiCharts Portfolio Trader, la plateforme de trading |
| **MoE** | Mixture of Experts, 5 modeles ML en competition pour la meilleure prediction |
| **NLV** | Net Liquidation Value, valeur totale du compte |
| **OOS** | Out-of-Sample, donnees jamais vues lors du developpement |
| **PnL** | Profit and Loss, profits et pertes |
| **RL** | Reinforcement Learning, apprentissage par retour d'experience |
| **RV** | Realized Volatility, combien une paire a reellement bouge |
| **VRP** | Volatility Risk Premium, difference entre IV et RV |
| **z-score** | Combien d'ecarts-types par rapport a la moyenne (2 = inhabituel, 4 = extreme) |

---

*Vous etes arrive a la fin de MoneyProd pour les Nuls. Le systeme est plus complexe que ce qu'un seul document peut pleinement capturer, mais si vous avez compris les 19 chercheurs, les 4 juges, les 9 boucliers de securite, la cascade de dimensionnement a 8 couches et les 32 strategies forgees a partir de 10 millions de candidates, vous comprenez l'architecture essentielle d'un systeme de trading autonome en production.*

*La machine ne dort pas. Elle ne panique pas. Elle n'espere pas. Elle execute simplement, heure apres heure, avec la precision mecanique d'un systeme concu pour avoir raison plus souvent qu'il n'a tort, et pour survivre aux moments ou il a tort.*
