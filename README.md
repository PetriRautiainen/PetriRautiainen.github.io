# Petri Rautiainen — henkilökohtainen analyysisivusto

Suomenkielinen Quarto-blogi datasta, sijoittamisesta ja riskienhallinnasta. Teksti, kysymykset, havainnot ja kuviot ovat pääosassa; analyysikoodi on oletuksena avattavaa.

- Sivusto: https://petrirautiainen.github.io
- Julkinen lähdekoodirepo: https://github.com/PetriRautiainen/PetriRautiainen.github.io
- Julkaisujen tila: https://github.com/PetriRautiainen/PetriRautiainen.github.io/actions

## Käyttö

Quarto-versio on 1.9.38, sama kuin GitHub Actionsissa.

- Julkinen versio: `quarto render`
- Luonnosten esikatselu: `quarto preview --profile preview`
- Artikkelipohja: kopioi `templates/article.qmd` uuteen `posts/aihe/index.qmd`-tiedostoon.
- Paikallinen esikatselu: `quarto preview`.

Aiheet ovat Data, Osakkeet, Korot, Vaihtoehtoiset sijoitukset, Riskienhallinta ja Minusta. Sivusto on henkilökohtainen eikä käytä työnantajan järjestelmiä, aineistoja tai tunnuksia.

## Automaattinen julkaisu

Repo on julkinen ja julkaisu käyttää maksutonta GitHub Pagesia. Pagesin lähteeksi on asetettu **Settings → Pages → Build and deployment → Source → GitHub Actions**.

`.github/workflows/publish.yml` rakentaa sivuston `main`-haaran päivityksistä ja julkaisee onnistuneen rakennuksen Pagesiin. Pull requestit rakennetaan ilman julkaisua. Ajon voi käynnistää myös käsin Actions-välilehdeltä. GitHub asentaa muuttamattoman virallisen Quarton.

Julkisen repon kaikki lähdetiedostot ovat julkisia, myös luonnokset. `draft: true` poistaa kirjoituksen sisällön sivuston julkisesta versiosta ja hausta, mutta ei piilota lähdetiedostoa GitHubissa. Quarto voi tuottaa luonnokselle tyhjän HTML-sivun.

`posts/normaalijakauma/index.qmd` säilyy luonnoksena. Se on erikseen merkitty matemaattinen esimerkki, ei empiirinen markkina-analyysi.

Omaa verkkotunnusta ei ole hankittu. `petrirautiainen.com`-osoitteen saatavuutta tai omistusta ei ole tarkistettu.

## Uusi kirjoitus Codexin kanssa

1. Anna kysymys, näkökulma ja mahdolliset lähteet.
2. Valmistele analyysi ja artikkeli henkilökohtaisessa ympäristössä.
3. Aloita kirjoitus asetuksella `draft: true`. Aseta `draft: false` vasta, kun julkaiseminen on pyydetty ja kirjoitus on tarkistettu.
4. Rakenna julkinen versio ja tarkista luvut, kuviot, linkit, ulkoasu ja luonnosten poisrajaus.
5. Vie muutokset `main`-haaraan ja varmista Actions-ajon sekä sivuston päivityksen onnistuminen.

## Datan ja laskennan hallinta

Käytä julkisia aineistoja, joiden käyttö- ja edelleenjulkaisuehdot sopivat tarkoitukseen, tai selvästi merkittyjä esimerkkiaineistoja. Dokumentoi lähteet, hakupäivä, havaintojakso ja rajaukset. Suuret raakadata-aineistot eivät kuulu automaattisesti repoon.

Quarton `freeze: true` säilyttää laskentatulokset. Suorita muuttuneen laskennallisen artikkelin laskenta tarkoituksella uudelleen ennen julkaisua. Tässä pohjassa ei ole Jupyter- tai R-ympäristöä; se lisätään ensimmäisen suoritettavaa koodia sisältävän artikkelin yhteydessä. Esimerkkiluonnos käyttää Pythonin standardikirjastoa tavallisessa koodilohkossa, jota Quarto ei suorita. Sen koodi on piilotettu HTML:n `details`-elementtiin.

## Tarkistuksen tila

10.10.2026: GitHub-pluginin yhdistetty identiteetti vahvistettiin tiliksi **PetriRautiainen** ja tälle tilille perustettiin julkinen **PetriRautiainen.github.io**-repo. Ensimmäinen GitHub Actions -ajo ja Pages-julkaisu ovat vielä tarkistamatta.

Julkinen versio ja luonnosten esikatselu rakennettiin Quarto 1.9.38:lla. Tarkistusversiot ovat `_site-check` ja `_preview-check`; niitä ei viedä GitHubiin. Molemmissa on yhdeksän HTML-sivua. Tarkistus vahvisti seuraavat asiat:

- Sisäiset tiedostolinkit ja resurssit löytyvät.
- Artikkelipohjaa ei julkaista.
- Aihekohtaiset listat suodattavat kirjoitukset oikein.
- Esimerkkiluonnoksen sisältö ja hakutulos puuttuvat julkisesta versiosta.
- Luonnoksen koodi on esikatselussa oletuksena suljettu.
- Python-laskenta tuottaa normaalimallille 0,135 % ja seosmallille 1,073 %; tekstin pyöristetyt luvut täsmäävät.

Paikallisen suoritusympäristön rajoitus esti Quarton tietokantavälimuistin käytön. Vain paikallisessa tarkistustyökalussa tietokantavälimuisti vaihdettiin muistiin ja muu välimuisti työskentelykansioon. Projektin lähdekoodi ja GitHub Actionsin Quarto-asennus eivät sisällä tätä muutosta.

Paikallinen esikatselu ei ollut saavutettavissa Codexin selaimessa. Ulkoasun tarkistus tehdään julkaistusta Pages-sivustosta; ulkoasua ei ole vielä vahvistettu.