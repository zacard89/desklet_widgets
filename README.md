# Desklet widgets

Katalog widgetów dla [Desklet](https://github.com/zacard89/Desklet). Desklet pobiera to repo kluczem tylko do odczytu
(deploy key) i pokazuje widgety w menu ✨ → **Katalog widgetów**.

## Format

Każdy widget to katalog:

```
nazwa-widgetu/
├── index.coffee      # albo index.js / nazwa-widgetu.coffee
├── widget.json       # opcjonalnie: {"description": "krótki opis do menu"}
├── lib/ assets/      # dowolne pliki widgetu; w kodzie: run("python3 lib/x.py"), asset("assets/x.png")
```

Ustawienia, które użytkownik ma wpisać sam (np. konto), deklaruj jako opcje z `type: 'text'` albo `'number'` –
Desklet pokaże je w oknie **Konfiguruj…**, a wartość trafi do pola widgetu o tej samej nazwie:

```coffee
options:
  name:
    label: 'Imię'
    type: 'text'
    default: 'zacard'
    help: 'Pokazywane w powitaniu.'
```

Zmiana katalogu widgetu w repo pojawia się w Desklet jako „Aktualizuj: …”.
