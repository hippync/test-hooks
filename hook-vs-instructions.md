# Hook vs. instructions `.md` — pourquoi ce n'est pas la même chose

Une question revient souvent : « si j'écris dans un fichier d'instructions
*N'efface jamais les données sensibles*, est-ce que ça ne suffit pas ? »

**Non.** Un fichier `.md` d'instructions et un hook ne jouent pas dans la même
catégorie. L'un **conseille**, l'autre **empêche**.

---

## La différence en une phrase

| | Instructions `.md` | Hook / point de contrôle |
|---|---|---|
| Nature | Texte lu par le **modèle** | Code exécuté par le **système** |
| Force | **Molle** — une recommandation | **Dure** — une barrière |
| Qui décide ? | Le LLM choisit de suivre… ou non | Le code décide, sans débat |
| Garantie | Probabiliste (« en général ») | Déterministe (« toujours ») |
| Contournable par le modèle ? | **Oui** | **Non** |

---

## Pourquoi le `.md` n'empêche PAS les actions dangereuses

Un fichier d'instructions (`copilot-instructions.md`, `.agent.md`,
`CLAUDE.md`, un *system prompt*…) est du **texte ajouté au contexte du LLM**.
Le modèle le lit, puis **génère** sa réponse de façon probabiliste. Rien ne
l'oblige à obéir. Concrètement, la consigne peut être ignorée quand :

- la demande de l'utilisateur est insistante ou contradictoire
  (« je sais ce que je fais, supprime-le quand même ») ;
- le contexte est long et l'instruction « se dilue » ;
- une injection de prompt détourne le modèle ;
- le modèle « hallucine » simplement qu'il a le droit.

Résultat : l'instruction réduit la *probabilité* d'une action dangereuse,
mais ne la ramène **jamais à zéro**. C'est une politesse, pas une serrure.

```
Instruction .md :  "merci de ne pas supprimer"   ->  le modèle PEUT quand même le faire
Hook / code     :  if action == "rm": refuse      ->  l'action N'A PAS LIEU
```

## Pourquoi le hook, lui, empêche vraiment

Un hook (ou tout point de contrôle dans **ton** code) s'exécute **en dehors**
du modèle, **entre** la décision et l'exécution :

```
LLM (propose une action)  ->  [ POINT DE CONTRÔLE ]  ->  exécution réelle
                                       │
                                       └─ si risqué : bloque, peu importe
                                          ce que le modèle « voulait »
```

Le LLM peut « vouloir » lancer `rm` autant qu'il veut : si le code refuse,
**il ne se passe rien**. La garantie ne dépend pas de la bonne volonté du
modèle — elle est mécanique.

---

## Analogie

- **Instructions `.md`** = un panneau « Défense d'entrer ». Dissuasif, mais
  une porte ouverte laisse passer quiconque l'ignore.
- **Hook / code** = une **porte verrouillée**. Le panneau peut être ignoré ;
  la serrure, non.

On met souvent **les deux** : le panneau évite la plupart des tentatives, la
serrure garantit le reste.

---

## Ce que ça implique pour la sécurité

1. **Ne jamais compter sur les instructions `.md` seules** pour empêcher une
   action destructrice. Elles guident, elles ne protègent pas.
2. Pour une **garantie**, il faut un mécanisme hors-modèle :
   - un **hook** (Claude Code) ;
   - une **deny-list / permission** (Copilot, et seulement « dure » pour le
     terminal, pas pour tout) ;
   - un **point de contrôle dans ton propre code** (le plus fiable : tu as la
     main à 100 %).
3. Le plus solide reste l'architecture : ce qui ne doit pas être faisable ne
   doit pas être **possible** (ex. ne pas donner l'outil terminal à l'agent),
   plutôt que simplement **déconseillé**.

> En résumé : une instruction `.md` agit sur ce que le modèle *a envie* de
> faire ; un hook agit sur ce qu'il *peut* faire. Pour la sécurité, seule la
> seconde compte.

---

## Dans cette démo

| Fichier | Type | Force |
|---|---|---|
| [`agent-avec-hooks/.claude/hooks/verifier_risque.sh`](agent-avec-hooks/.claude/hooks/verifier_risque.sh) | Hook (code) | **Dure** — bloque vraiment |
| [`agent-securise.agent.md`](.github/agents/agent-securise.agent.md) — consignes de refus | Instructions `.md` | **Molle** — peut être ignorée |
| [`agent-securise.agent.md`](.github/agents/agent-securise.agent.md) — champ `tools` sans `runCommands` | Restriction d'outil (code) | **Dure** — l'action devient impossible |
| [`.vscode/settings.json`](.vscode/settings.json) — deny-list terminal | Permission système | **Dure** (terminal seulement) |

Le fichier `.agent.md` mélange donc les deux : ses *consignes* sont molles,
mais sa *liste d'outils* est un vrai garde-fou.
