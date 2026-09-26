import json
import re

INPUT_FILE = "premade_decks.json"
OUTPUT_FILE = "premade_decks_sk.json"

# Slovníky prekladov
COUNTRY_SK = {
    "Afghanistan": "Afganistan", "Albania": "Albánsko", "Algeria": "Alžírsko",
    "Andorra": "Andorra", "Angola": "Angola", "Antigua and Barbuda": "Antigua a Barbuda",
    "Argentina": "Argentína", "Armenia": "Arménsko", "Australia": "Austrália",
    "Austria": "Rakúsko", "Azerbaijan": "Azerbajdžan", "Bahamas": "Bahamy",
    "Bahrain": "Bahrajn", "Bangladesh": "Bangladéš", "Barbados": "Barbados",
    "Belarus": "Bielorusko", "Belgium": "Belgicko", "Belize": "Belize",
    "Benin": "Benin", "Bhutan": "Bhután", "Bolivia": "Bolívia",
    "Bosnia and Herzegovina": "Bosna a Hercegovina", "Botswana": "Botswana",
    "Brazil": "Brazília", "Brunei": "Brunej", "Bulgaria": "Bulharsko",
    "Burkina Faso": "Burkina Faso", "Burundi": "Burundi", "Cabo Verde": "Kapverdy",
    "Cambodia": "Kambodža", "Cameroon": "Kamerun", "Canada": "Kanada",
    "Central African Republic": "Stredoafrická republika", "Chad": "Čad",
    "Chile": "Čile", "China": "Čína", "Colombia": "Kolumbia", "Comoros": "Komory",
    "Congo (Congo-Brazzaville)": "Kongo", "Congo": "Kongo", "Costa Rica": "Kostarika",
    "Croatia": "Chorvátsko", "Cuba": "Kuba", "Cyprus": "Cyprus",
    "Czech Republic": "Česko", "Democratic Republic of the Congo": "Kongo (DRK)",
    "Denmark": "Dánsko", "Djibouti": "Džibutsko", "Dominica": "Dominika",
    "Dominican Republic": "Dominikánska republika", "East Timor (Timor-Leste)": "Východný Timor",
    "East Timor": "Východný Timor", "Ecuador": "Ekvádor", "Egypt": "Egypt",
    "El Salvador": "Salvádor", "Equatorial Guinea": "Rovníková Guinea",
    "Eritrea": "Eritrea", "Estonia": "Estónsko", "Eswatini": "Eswatini",
    "Ethiopia": "Etiópia", "Fiji": "Fidži", "Finland": "Fínsko",
    "France": "Francúzsko", "Gabon": "Gabon", "Gambia": "Gambia",
    "Georgia": "Gruzínsko", "Germany": "Nemecko", "Ghana": "Ghana",
    "Greece": "Grécko", "Grenada": "Grenada", "Guatemala": "Guatemala",
    "Guinea": "Guinea", "Guinea-Bissau": "Guinea-Bissau", "Guyana": "Guyana",
    "Haiti": "Haiti", "Honduras": "Honduras", "Hungary": "Maďarsko",
    "Iceland": "Island", "India": "India", "Indonesia": "Indonézia",
    "Iran": "Irán", "Iraq": "Irak", "Ireland": "Írsko", "Israel": "Izrael",
    "Italy": "Taliansko", "Ivory Coast": "Pobrežie Slonoviny", "Jamaica": "Jamajka",
    "Japan": "Japonsko", "Jordan": "Jordánsko", "Kazakhstan": "Kazachstan",
    "Kenya": "Keňa", "Kiribati": "Kiribati", "Kuwait": "Kuvajt",
    "Kyrgyzstan": "Kirgizsko", "Laos": "Laos", "Latvia": "Lotyšsko",
    "Lebanon": "Libanon", "Lesotho": "Lesotho", "Liberia": "Libéria",
    "Libya": "Líbya", "Liechtenstein": "Lichtenštajnsko", "Lithuania": "Litva",
    "Luxembourg": "Luxembursko", "Madagascar": "Madagaskar", "Malawi": "Malawi",
    "Malaysia": "Malajzia", "Maldives": "Maledivy", "Mali": "Mali",
    "Malta": "Malta", "Marshall Islands": "Marshallove ostrovy",
    "Mauritania": "Mauritánia", "Mauritius": "Maurícius", "Mexico": "Mexiko",
    "Micronesia": "Mikronézia", "Moldova": "Moldavsko", "Monaco": "Monako",
    "Mongolia": "Mongolsko", "Montenegro": "Čierna Hora", "Morocco": "Maroko",
    "Mozambique": "Mozambik", "Myanmar": "Mjanmarsko", "Namibia": "Namíbia",
    "Nauru": "Nauru", "Nepal": "Nepál", "Netherlands": "Holandsko",
    "New Zealand": "Nový Zéland", "Nicaragua": "Nikaragua", "Niger": "Niger",
    "Nigeria": "Nigéria", "North Korea": "Severná Kórea", "North Macedonia": "Severné Macedónsko",
    "Norway": "Nórsko", "Oman": "Omán", "Pakistan": "Pakistan",
    "Palau": "Palau", "Palestine": "Palestína", "Panama": "Panama",
    "Papua New Guinea": "Papua-Nová Guinea", "Paraguay": "Paraguaj",
    "Peru": "Peru", "Philippines": "Filipíny", "Poland": "Poľsko",
    "Portugal": "Portugalsko", "Qatar": "Katar", "Romania": "Rumunsko",
    "Russia": "Rusko", "Rwanda": "Rwanda", "Saint Kitts and Nevis": "Svätý Krištof a Nevis",
    "Saint Lucia": "Svätá Lucia", "Saint Vincent and the Grenadines": "Svätý Vincent a Grenadíny",
    "Samoa": "Samoa", "San Marino": "San Maríno", "Sao Tome and Principe": "Svätý Tomáš a Princov ostrov",
    "Saudi Arabia": "Saudská Arábia", "Senegal": "Senegal", "Serbia": "Srbsko",
    "Seychelles": "Seychely", "Sierra Leone": "Sierra Leone", "Singapore": "Singapur",
    "Slovakia": "Slovensko", "Slovenia": "Slovinsko", "Solomon Islands": "Šalamúnove ostrovy",
    "Somalia": "Somálsko", "South Africa": "Južná Afrika", "South Korea": "Južná Kórea",
    "South Sudan": "Južný Sudán", "Spain": "Španielsko", "Sri Lanka": "Srí Lanka",
    "Sudan": "Sudán", "Suriname": "Surinam", "Sweden": "Švédsko",
    "Switzerland": "Švajčiarsko", "Syria": "Sýria", "Tajikistan": "Tadžikistan",
    "Tanzania": "Tanzánia", "Thailand": "Thajsko", "Togo": "Togo",
    "Tonga": "Tonga", "Trinidad and Tobago": "Trinidad a Tobago",
    "Tunisia": "Tunisko", "Turkey": "Turecko", "Turkmenistan": "Turkménsko",
    "Tuvalu": "Tuvalu", "Uganda": "Uganda", "Ukraine": "Ukrajina",
    "United Arab Emirates": "Spojené arabské emiráty", "United Kingdom": "Spojené kráľovstvo",
    "United States": "Spojené štáty", "Uruguay": "Uruguaj", "Uzbekistan": "Uzbekistan",
    "Vanuatu": "Vanuatu", "Vatican City": "Vatikán", "Venezuela": "Venezuela",
    "Vietnam": "Vietnam", "Yemen": "Jemen", "Zambia": "Zambia", "Zimbabwe": "Zimbabwe"
}

CAPITAL_SK = {
    "Kabul": "Kábul", "Algiers": "Alžír", "Yerevan": "Jerevan", "Vienna": "Viedeň",
    "Brussels": "Brusel", "Phnom Penh": "Phnom Pénh", "Beijing": "Peking",
    "Bogotá": "Bogota", "Zagreb": "Záhreb", "Havana": "Havana", "Nicosia": "Nikózia",
    "Prague": "Praha", "Copenhagen": "Kodaň", "Djibouti": "Džibuti", "Cairo": "Káhira",
    "Athens": "Atény", "Guatemala City": "Guatemala", "Conakry": "Konakry",
    "Budapest": "Budapešť", "Reykjavik": "Reykjavík", "New Delhi": "Nové Dillí",
    "Tehran": "Teherán", "Baghdad": "Bagdad", "Jerusalem": "Jeruzalem", "Rome": "Rím",
    "Tokyo": "Tokio", "Amman": "Ammán", "Kuwait City": "Kuvajt", "Bishkek": "Biškek",
    "Beirut": "Bejrút", "Tripoli": "Tripolis", "Luxembourg": "Luxemburg",
    "Mexico City": "Mexiko", "Chisinau": "Kišiňov", "Monaco": "Monako",
    "Ulaanbaatar": "Ulanbátar", "Panama City": "Panama", "Warsaw": "Varšava",
    "Lisbon": "Lisabon", "Doha": "Dauha", "Bucharest": "Bukurešť", "Moscow": "Moskva",
    "Riyadh": "Rijád", "Belgrade": "Belehrad", "Singapore": "Singapur",
    "Ljubljana": "Ľubľana", "Mogadishu": "Mogadišo", "Pretoria": "Pretória",
    "Seoul": "Soul", "Khartoum": "Chartúm", "Stockholm": "Štokholm", "Damascus": "Damašok",
    "Dushanbe": "Dušanbe", "Ashgabat": "Ašchabad", "Kyiv": "Kyjev", "Abu Dhabi": "Abú Zabí",
    "London": "Londýn", "Tashkent": "Taškent", "Vatican City": "Vatikán",
    "Hanoi": "Hanoj", "Sana'a": "Saná"
}

HTTP_STATUS_SK = {
    "Continue": "Pokračovať", "Switching Protocols": "Prepínanie protokolov",
    "Processing": "Spracováva sa", "Early Hints": "Skoré náznaky",
    "OK": "OK (Úspešné)", "Created": "Vytvorené", "Accepted": "Prijaté",
    "Non-Authoritative Information": "Neautorizované informácie", "No Content": "Bez obsahu",
    "Reset Content": "Obnoviť obsah", "Partial Content": "Čiastočný obsah",
    "Multi-Status": "Viacero stavov", "Already Reported": "Už nahlásené",
    "IM Used": "IM použité", "Multiple Choices": "Viacero možností",
    "Moved Permanently": "Trvalo presunuté", "Found (Temporary Redirect)": "Nájdené (Dočasné presmerovanie)",
    "See Other": "Pozri iné", "Not Modified": "Nezmenené",
    "Temporary Redirect": "Dočasné presmerovanie", "Permanent Redirect": "Trvalé presmerovanie",
    "Bad Request": "Zlá požiadavka", "Unauthorized": "Neautorizované",
    "Payment Required": "Vyžaduje sa platba", "Forbidden": "Zakázané",
    "Not Found": "Nenájdené", "Method Not Allowed": "Metóda nie je povolená",
    "Not Acceptable": "Neprijateľné", "Proxy Authentication Required": "Vyžaduje sa overenie proxy",
    "Request Timeout": "Časový limit požiadavky vypršal", "Conflict": "Konflikt",
    "Gone": "Odstránené", "Length Required": "Vyžaduje sa dĺžka",
    "Precondition Failed": "Zlyhala predbežná podmienka", "Payload Too Large": "Príliš veľké dáta",
    "URI Too Long": "URI príliš dlhé", "Unsupported Media Type": "Nepadporovaný typ média",
    "Range Not Satisfiable": "Rozsah nie je splniteľný", "Expectation Failed": "Očakávanie zlyhalo",
    "I'm a teapot": "Som kanvica na čaj", "Misdirected Request": "Chybne nasmerovaná požiadavka",
    "Unprocessable Entity": "Nespracovateľná entita", "Locked": "Zamknuté",
    "Failed Dependency": "Zlyhala závislosť", "Too Early": "Príliš skoro",
    "Upgrade Required": "Vyžaduje sa aktualizácia", "Precondition Required": "Vyžaduje sa predbežná podmienka",
    "Too Many Requests": "Príliš veľa požiadaviek", "Request Header Fields Too Large": "Hlavičky požiadavky sú príliš veľké",
    "Unavailable For Legal Reasons": "Nedostupné z právnych dôvodov",
    "Internal Server Error": "Vnútorná chyba servera", "Not Implemented": "Neimplementované",
    "Bad Gateway": "Zlá brána", "Service Unavailable": "Služba nedostupná",
    "Gateway Timeout": "Časový limit brány vypršal", "HTTP Version Not Supported": "Verzia HTTP nie je podporovaná",
    "Variant Also Negotiates": "Variant tiež vyjednáva", "Insufficient Storage": "Nedostatok miesta",
    "Loop Detected": "Zistená slučka", "Network Authentication Required": "Vyžaduje sa sieťové overenie"
}

WORD_TRANSLATIONS = {
    "Time / Weather": "Čas / Počasie", "Year": "Rok", "People": "Ľudia", "Man": "Muž",
    "Woman": "Žena", "Woman / Wife": "Žena / Manželka", "Man / Husband": "Muž / Manžel",
    "Child": "Dieťa", "Life": "Život", "Day": "Deň", "Thing": "Vec", "Thing / Matter": "Vec / Záležitosť",
    "World": "Svet", "House": "Dom", "House / Building": "Dom / Budova", "Work / Job": "Práca / Zamestnanie",
    "Part": "Časť", "Place": "Miesto", "Government": "Vláda", "Case": "Prípad", "Group": "Skupina",
    "Problem": "Problém", "Fact": "Fakt / Skutočnosť", "Hand": "Ruka", "Hand / Arm": "Ruka",
    "Eye": "Oko", "Hour / Time": "Hodina / Čas", "Hour": "Hodina", "Hour / Lesson": "Hodina / Lekcia",
    "Truth": "Pravda", "Water": "Voda", "Mother": "Matka", "Father": "Otec", "Friend": "Priateľ",
    "Family": "Rodina", "Money": "Peniaze", "Money / Silver": "Peniaze / Striebro", "Night": "Noc",
    "City": "Mesto", "City / Town": "Mesto", "Name": "Meno", "Country": "Krajina",
    "Country / Land": "Krajina / Zem", "Country / Earth / Land": "Krajina / Zem", "Question": "Otázka",
    "Door": "Dvere", "Street": "Ulica", "Book": "Kniha", "Word": "Slovo", "Side": "Strana",
    "Side / Page": "Strana / Stránka", "Page / Side": "Stránka / Strana", "Son / Child": "Syn / Dieťa",
    "Son": "Syn", "Daughter": "Dcéra", "Daughter / Girl": "Dcéra / Dievča", "Boy / Son": "Chlapec / Syn",
    "Girl / Daughter": "Dievča / Dcéra", "Moment": "Chvíľa / Moment", "Body": "Telo",
    "Head": "Hlava", "Sun": "Slnko", "Light": "Svetlo", "Dog": "Pes", "Cat": "Mačka", "Food": "Jedlo",
    "Love": "Láska", "Air": "Vzduch", "Air / Weather": "Vzduch / Počasie", "Sea": "More",
    "To be (permanent)": "Byť (trvalo)", "To be (temporary)": "Byť (prechodne)", "To be": "Byť",
    "To be / To have": "Byť / Mať", "To do / To make": "Robiť / Urobiť", "To have": "Mať",
    "To go": "Ísť", "To say / To tell": "Povedať / Hovoriť", "To say": "Povedať",
    "To be able to / Can": "Môcť / Vedieť", "Can / To be able to": "Môcť", "To see": "Vidieť",
    "To eat": "Jesť", "To drink": "Piť", "To speak / To talk": "Hovoriť / Rozprávať", "To speak": "Hovoriť",
    "To know (facts)": "Vedieť (fakty)", "To want / To love": "Chcieť / Ľúbiť", "To want": "Chcieť",
    "To arrive": "Prísť / Doraziť", "To pass / To happen": "Prejsť / Stať sa", "To pass / To spend time": "Prejsť / Stráviť čas",
    "Must / Should": "Musiť / Mal by", "Must / To have to": "Musiť", "To put": "Položiť / Dať",
    "To seem": "Zdať sa", "To stay / To remain": "Ostať / Zostať", "To believe": "Veriť",
    "To carry / To wear": "Nosiť", "To leave / To allow": "Nechať / Dovoliť", "To follow / To continue": "Sledovať / Pokračovať",
    "To follow": "Sledovať", "To find": "Nájsť", "To call": "Motať / Volať", "To think": "Myslieť",
    "To think / To consider": "Myslieť / Uvažovať", "To leave / To exit": "Odisť / Vyjsť",
    "To return / To come back": "Vrátiť sa", "To take / To drink": "Vziať / Piť", "To take": "Vziať",
    "To know (people/places)": "Poznať (ľudí/miesta)", "To live": "Žiť", "To feel": "Cítiť",
    "To feel / To know (people)": "Cítiť / Poznať", "To write": "Písať", "To read": "Čítať",
    "To open": "Otvoriť", "To close": "Zatvoriť", "To buy": "Kúpiť", "To sell": "Predať",
    "To work": "Pracovať", "To study": "Študovať", "To learn": "Učiť sa", "To understand": "Rozumieť",
    "To help": "Pomôcť", "To play (games/sports)": "Hrať (hry/športy)", "To play": "Hrať",
    "To listen": "Počúvať", "To look at": "Poerať sa na", "To look at / To watch": "Pozerať sa / Sledovať",
    "To watch / To look": "Sledovať / Pozerať", "To search / To look for": "Hľadať", "To pay": "Platiť",
    "To pay / To cost": "Platiť / Stáť (cenu)", "To sleep": "Spať", "To change": "Zmeniť",
    "To change / To move": "Zmeniť / Presťahovať", "Big / Large": "Veľký", "Big / Tall": "Veľký / Vysoký",
    "Small / Little": "Malý", "Good": "Dobrý", "Bad": "Zlý", "Bad / Evil": "Zlý", "New": "Nový",
    "Old": "Starý", "First": "Prvý", "Last": "Posledný", "Long": "Dlhý", "Long / Tall": "Dlhý / Vysoký",
    "Tall / High": "Vysoký", "High": "Vysoký", "High / Tall": "Vysoký", "Short / Low": "Nízky",
    "Young": "Mladý", "Easy": "Ľahký", "Easy / Simple": "Jednoduchý / Ľahký", "Difficult": "Ťažký / Náročný",
    "Difficult / Hard": "Ťažký / Náročný", "Important": "Dôležitý", "Same": "Rovnaký",
    "Same / Equal": "Rovnaký / Rovný", "Different": "Iný", "Other / Another": "Iný / Ďalší",
    "Other / Second": "Iný / Druhý", "Alone": "Sám", "Alone / Only": "Sám / Iba", "Fast / Quick": "Rýchly",
    "Slow": "Pomalý", "Happy": "Šťastný", "Sad": "Smutný", "Tired": "Unavený", "Pretty / Nice": "Pekný",
    "Beautiful / Nice": "Krásny / Pekný", "Beautiful / Handsome": "Krásny / Pekný", "Beautiful": "Krásny",
    "Ugly": "Škaredý", "Hot": "Horúci", "Cold": "Studený", "Clean": "Čistý", "Clean / Own": "Čistý / Vlastný",
    "Dirty": "Špinavý", "Full": "Plný", "Empty": "Prázdny", "Strong": "Silný", "Rich": "Bohatý",
    "Rich / Delicious": "Bohatý / Chutný", "Poor": "Chudobný", "Close / Near": "Blízko",
    "Near / Close": "Blízko", "Far": "Ďaleko", "Far away": "Ďaleko", "Early": "Skoro / Früh",
    "On time / Early": "Na čas / Skoro", "Late": "Neskoro", "Always": "Vždy", "Always / Still": "Vždy / Stále",
    "Never": "Nikdy", "Sometimes": "Občas / Niekedy", "Now": "Teraz", "Today": "Dnes",
    "Yesterday": "Včera", "Tomorrow": "Zajtra", "Tomorrow / Morning": "Zajtra / Ráno", "Here": "Tu",
    "There": "Tam", "Much / A lot": "Veľa", "A lot / Much": "Veľa", "Little / Few": "Málo",
    "A little / Few": "Trochu / Málo", "More": "Viac", "Less": "Menej", "Very": "Veľmi",
    "Well / Very": "Labi / Veľmi", "Also / Too": "Taktiež / Aj", "Neither / Either": "Anii (nie)",
    "Yes": "Áno", "No": "Nie", "Maybe": "Možno", "Maybe / Perhaps": "Možno / Aďaj",
    "Well / Fine": "Dobre", "Badly / Poorly": "Zle", "Hello": "Ahoj / Dobrý deň",
    "Hello / Good morning": "Dobrý deň", "Hello / Hi": "Ahoj", "Goodbye": "Dovidenia",
    "Please": "Prosím", "Please / You're welcome": "Prosím / Nie je za čo", "Please (formal)": "Prosím",
    "Thank you": "Ďakujem", "You're welcome": "Nie je za čo", "I'm sorry": "Prepáčte / Je mi to ľúto",
    "Excuse me": "Prepáčte", "Excuse me / Sorry": "Prepáčte", "Sorry / Excuse me": "Prepáčte",
    "I": "Ja", "You (informal)": "Ty", "You (singular)": "Ty", "He": "On", "He / It": "On / To",
    "She": "Ona", "She / It": "Ona / To", "She / They / You (formal)": "Ona / Oni / Vy", "It": "To",
    "We": "My", "They": "Oni", "They (masculine)": "Oni", "They (feminine)": "Ony",
    "You (formal)": "Vy", "You (plural)": "Vy", "You (plural/formal)": "Vy", "What": "Čo",
    "Who": "Kto", "Where": "Kde", "When": "Kedy", "Why": "Prečo", "How": "Ako",
    "How much": "Koľko", "How much / How many": "Koľko", "And": "A", "Or": "Alebo", "But": "Ale",
    "Because": "Pretože", "If": "Ak", "If / When": "Ak / Keď", "Like / As": "Ako",
    "For / To": "Pre / Na", "For / By": "Pre / Od", "For / In order to": "Pre / Aby", "For": "Pre",
    "With": "S", "Without": "Bez", "In / On / At": "V / Na", "In / Inside": "V / Vo vnútri",
    "In": "V", "Of / From": "Z / Od", "From / Of": "Od / Z", "To / At": "K / Na", "To": "K",
    "About / On top of": "O / Na", "Over / About": "Nad / O", "Between / Among": "Medzi",
    "Between": "Medzi", "Until": "Až do", "From / Since": "Od", "Trip / Journey": "Cesta / Výlet",
    "School": "Škola", "Table": "Stôl", "Chair": "Stolička", "Car": "Auto", "Window": "Okno",
    "Key": "Kľúč", "Clock / Watch": "Hodiny / Hodinky", "Picture / Image": "Obrázok",
    "Newspaper": "Noviny", "Phone": "Telefón", "Computer": "Počítač", "Forest": "Les",
    "Lake": "Jazero", "Sky / Heaven": "Nebo", "Flower": "Kvet", "Home": "Domov"
}

DECK_METADATA_SK = {
    "World Capitals": {"name": "Hlavné mestá sveta", "category": "Geografia", "front_lang": "sk-SK", "back_lang": "sk-SK"},
    "World Flags": {"name": "Vlajky sveta", "category": "Geografia", "front_lang": "en-US", "back_lang": "sk-SK"},
    "Spanish Top 200 Words": {"name": "Španielčina – Top 200 slov", "category": "Jazyky", "front_lang": "es-ES", "back_lang": "sk-SK"},
    "German Top 200 Words": {"name": "Nemčina – Top 200 slov", "category": "Jazyky", "front_lang": "de-DE", "back_lang": "sk-SK"},
    "French Top 200 Words": {"name": "Francúzština – Top 200 slov", "category": "Jazyky", "front_lang": "fr-FR", "back_lang": "sk-SK"},
    "Finnish Top 200 Words": {"name": "Fínština – Top 200 slov", "category": "Jazyky", "front_lang": "fi-FI", "back_lang": "sk-SK"},
    "HTTP Status Codes": {"name": "HTTP stavové kódy", "category": "Technológie", "front_lang": "en-US", "back_lang": "sk-SK"},
    "Essential Linux Commands": {"name": "Základné Linux príkazy", "category": "Technológie", "front_lang": "sk-SK", "back_lang": "en-US"}
}

def translate_linux_prompt(en_prompt):
    p = en_prompt
    p = p.replace("Command to ", "Príkaz na ").replace("Command for ", "Príkaz pre ")
    p = p.replace("list directory contents", "výpis obsahu adresára")
    p = p.replace("change current working directory", "zmenu aktuálneho pracovného adresára")
    p = p.replace("print current working directory path", "vypísanie cesty k aktuálnemu adresáru")
    p = p.replace("create a new directory", "vytvorenie nového adresára")
    p = p.replace("remove an empty directory", "odstránenie prázdneho adresára")
    p = p.replace("remove files or directories", "odstránenie súborov alebo adresárov")
    p = p.replace("copy files or directories", "kopírovanie súborov alebo adresárov")
    p = p.replace("move or rename files and directories", "presun alebo premenovanie súborov a adresárov")
    p = p.replace("create an empty file or update timestamps", "vytvorenie prázdneho súboru alebo aktualizáciu časových pečiatok")
    p = p.replace("display file contents on terminal", "zobrazenie obsahu súboru v termináli")
    p = p.replace("view file contents page by page", "zobrazenie obsahu súboru po stránkach")
    p = p.replace("view the first few lines of a file", "zobrazenie prvých niekoľkých riadkov súboru")
    p = p.replace("view the last few lines of a file", "zobrazenie posledných niekoľkých riadkov súboru")
    p = p.replace("search text matching a pattern inside files", "vyhľadávanie textu podľa vzoru v súboroch")
    p = p.replace("search for files and directories in directory tree", "vyhľadávanie súborov a adresárov v strome adresárov")
    p = p.replace("change file permissions", "zmenu prístupových práv súboru")
    p = p.replace("change file owner and group", "zmenu vlastníka a skupiny súboru")
    p = p.replace("execute command with superuser (root) privileges", "spustenie príkazu s právami správcu (root)")
    p = p.replace("display running processes in real-time", "zobrazenie bežiacich procesov v reálnom čase")
    p = p.replace("kill a process by PID", "ukončenie procesu podľa PID")
    p = p.replace("kill processes by name", "ukončenie procesov podľa názvu")
    p = p.replace("report a snapshot of current processes", "zobrazenie snímky aktuálnych procesov")
    p = p.replace("check disk space usage of filesystems", "kontrolu využitia miesta na disku")
    p = p.replace("estimate file and directory space usage", "odhad využitia miesta súbormi a adresármi")
    p = p.replace("display amount of free and used memory (RAM)", "zobrazenie voľnej a použitej pamäte (RAM)")
    p = p.replace("output text or variable values to terminal", "výpis textu alebo hodnôt premenných do terminálu")
    p = p.replace("clear terminal screen", "vyčistenie obrazovky terminálu")
    p = p.replace("show user command history", "zobrazenie histórie príkazov používateľa")
    p = p.replace("manage network interfaces and IP addresses", "spravovanie sieťových rozhraní a IP adries")
    p = p.replace("send ICMP echo requests to test network connectivity", "odosielanie ICMP požiadaviek na test sieťového spojenia")
    p = p.replace("download files from web via HTTP/HTTPS/FTP", "sťahovanie súborov z webu cez HTTP/HTTPS/FTP")
    p = p.replace("transfer data from or to a server using URL syntax", "prenos dát zo servera alebo na server pomocou URL")
    p = p.replace("store and extract files from a tape archive", "ukladanie a rozbaľovanie súborov z archívu (tar)")
    p = p.replace("compress files into zip format", "kompresiu súborov do formátu zip")
    p = p.replace("extract zip archives", "rozbalenie zip archívov")
    p = p.replace("connect to remote server securely via terminal", "zabezpečené pripojenie k vzdialenému serveru")
    p = p.replace("copy files securely between hosts over SSH", "zabezpečené kopírovanie súborov cez SSH")
    p = p.replace("synchronize files efficiently between two locations", "efektívnu synchronizáciu súborov medzi dvoma miestami")
    p = p.replace("display system kernel and architecture information", "zobrazenie informácií o jadre a architektúre systému")
    p = p.replace("display current logged-in username", "zobrazenie mena aktuálne prihláseného používateľa")
    p = p.replace("display system uptime and load average", "zobrazenie doby behu systému a zaťaženia")
    p = p.replace("control systemd system and service manager", "ovládanie systému a správcu služieb systemd")
    p = p.replace("view system logs managed by systemd", "zobrazenie systémových denníkov (logov)")
    p = p.replace("create links between files", "vytváranie odkazov medzi súbormi")
    p = p.replace("count lines, words, and bytes in a file", "spočítanie riadkov, slov a bajtov v súbore")
    p = p.replace("sort lines of text files", "zotriedenie riadkov textových súborov")
    p = p.replace("report or omit repeated lines", "vynechanie alebo zobrazenie opakujúcich sa riadkov")
    p = p.replace("stream editor for filtering and transforming text", "Prúdový editor na filtrovanie a úpravu textu")
    p = p.replace("pattern scanning and processing language", "Príkaz na vyhľadávanie vzorov a spracovanie textu")
    p = p.replace("display manual page for any command", "zobrazenie manuálovej stránky pre príkaz")
    p = p.replace("locate executable path of a command", "vyhľadanie cesty k spustiteľnému súboru príkazu")
    p = p.replace("change user password", "zmenu hesla používateľa")
    p = p.replace("reboot the system", "reštartovanie systému")
    p = p.replace("power off or shut down the machine", "vypnutie počítača")
    p = p.replace("mount a filesystem", "pripojenie (mount) súborového systému")
    p = p.replace("unmount a mounted filesystem", "odpojenie súborového systému")
    p = p.replace("print or modify environment variables", "výpis alebo úpravu premenných prostredia")
    p = p.replace("set environment variables for child processes", "nastavenie premenných prostredia pre podprocesy")
    p = p.replace("schedule periodic background jobs", "plánovanie pravidelných úloh na pozadí")
    p = p.replace("exit current shell session", "ukončenie aktuálnej relácie shellu")
    p = p.replace("search for commands in the PATH by name", "vyhľadávanie príkazov v PATH podľa názvu")
    p = p.replace("display alias definitions or create new ones", "zobrazenie alebo vytvorenie aliasov")
    p = p.replace("remove an alias", "odstránenie aliasu")
    p = p.replace("output the last part of a file or pipe", "presmerovanie výstupu do súboru aj na terminál (tee)")
    p = p.replace("run a command immune to hangups", "spustenie príkazu odolného voči odpojeniu relácie")
    p = p.replace("change root directory for current process", "zmenu koreňového adresára pre aktuálny proces")
    p = p.replace("print user and group IDs", "zobrazenie ID používateľa a skupín")
    p = p.replace("print the name of current terminal", "zobrazenie názvu aktuálneho terminálu")
    p = p.replace("delay execution for a specified time", "pozastavenie vykonávania na určený čas")
    p = p.replace("merge lines of files side-by-side", "spojenie riadkov súborov vedľa seba")
    p = p.replace("translate or delete characters from input stream", "nahradenie alebo zmazanie znakov vo vstupe")
    p = p.replace("split a file into pieces", "rozdelenie súboru na časti")
    p = p.replace("convert tabs to spaces or vice versa", "prevod tabulátorov na medzery")
    p = p.replace("view open files and processes using them", "zobrazenie otvorených súborov a procesov")
    p = p.replace("trace system calls and signals", "sledovanie systémových volaní a signálov")
    return p

def process_deck(deck):
    name = deck["name"]
    meta = DECK_METADATA_SK.get(name, {
        "name": name,
        "category": deck.get("category", ""),
        "front_lang": "sk-SK",
        "back_lang": "sk-SK"
    })

    cards = []
    for card in deck.get("cards", []):
        prompt = card["prompt"]
        ans = card["correct_answer"]

        if name == "World Capitals":
            match = re.match(r"Capital of (.*?) (\u00a0?[\U0001F1E6-\U0001F1FF]{2})", prompt)
            if match:
                c_en, flag = match.group(1), match.group(2)
                c_sk = COUNTRY_SK.get(c_en, c_en)
                p_sk = f"Hlavné mesto: {c_sk} {flag}"
            else:
                p_sk = prompt
            a_sk = CAPITAL_SK.get(ans, ans)
            cards.append({"prompt": p_sk, "correct_answer": a_sk})

        elif name == "World Flags":
            a_sk = COUNTRY_SK.get(ans, ans)
            cards.append({"prompt": prompt, "correct_answer": a_sk})

        elif "Top 200 Words" in name:
            a_sk = WORD_TRANSLATIONS.get(ans, ans)
            cards.append({"prompt": prompt, "correct_answer": a_sk})

        elif name == "HTTP Status Codes":
            a_sk = HTTP_STATUS_SK.get(ans, ans)
            cards.append({"prompt": prompt, "correct_answer": a_sk})

        elif name == "Essential Linux Commands":
            p_sk = translate_linux_prompt(prompt)
            cards.append({"prompt": p_sk, "correct_answer": ans})

        else:
            cards.append({"prompt": prompt, "correct_answer": ans})

    return {
        "name": meta["name"],
        "category": meta["category"],
        "is_premade": 1,
        "front_lang": meta["front_lang"],
        "back_lang": meta["back_lang"],
        "cards": cards
    }

def main():
    try:
        with open(INPUT_FILE, "r", encoding="utf-8") as f:
            decks = json.load(f)
    except FileNotFoundError:
        print(f"Chyba: Súbor {INPUT_FILE} nebol nájdený v aktuálnej zložke.")
        return

    sk_decks = [process_deck(d) for d in decks]

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(sk_decks, f, ensure_ascii=False, indent=2)

    print(f"Úspešne vytvorený {OUTPUT_FILE} s {len(sk_decks)} balíčkami.")

if __name__ == "__main__":
    main()