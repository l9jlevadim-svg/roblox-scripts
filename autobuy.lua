-- ============================================================
-- 1. ТВОЙ u1 (если есть) или пустой
-- ============================================================
local u1 = {}

-- ============================================================
-- 2. КАТАЛОГ TSUM (встроенный, не трогай)
-- ============================================================
local AUTOBUY_CATALOG_PARTS = {
    ["Common"] = [=[{["Common"] = { { n = "Белая футболка",i = 1352050969,s = 55.0,p = 120 },{ n = "Черная футболка",i = 6174845177,s = 55.0,p = 120 },{ n = "Синие джинсы",i = 9367316394,s = 50.0,p = 150 },{ n = "Черные джинсы",i = 8425198358,s = 50.0,p = 150 },{ n = "Серая футболка",i = 114724377,s = 45.0,p = 180 },{ n = "Nike Черная",i = 12820715433,s = 40.0,p = 900 },{ n = "Gutta Opiu White",i = 125787142138788,s = 38.0,p = 500 },{ n = "Nike Шорты",i = 6982632122,s = 38.0,p = 800 },{ n = "Amiri Футболка Черная2",i = 89306530816863,s = 20.0,p = 3200 },}}]=],
    ["Uncommon"] = [=[{["Uncommon"] = { { n = "Gutta Classic White Longsleeve",i = 81243747834531,s = 35.0,p = 1200 },{ n = "Gutta Longsleeve Pink Blue",i = 121948527526959,s = 35.0,p = 1200 },{ n = "Gutta Opiu Tee",i = 129923898671032,s = 35.0,p = 1200 },{ n = "Stussy Stock Logo Tee",i = 1352050969,s = 32.0,p = 1600 },{ n = "Carhartt Hoodie",i = 6174845177,s = 30.0,p = 2000 },{ n = "Palace Tri-Ferg Tee",i = 1352050969,s = 30.0,p = 2200 },{ n = "Carhartt Double Knee",i = 8425198358,s = 28.0,p = 2500 },{ n = "Nike x Stussy",i = 17303641875,s = 28.0,p = 1400 },{ n = "Stussy Work Pants",i = 8425198358,s = 28.0,p = 2200 },{ n = "Palace Track Pants",i = 8425198358,s = 25.0,p = 2800 },{ n = "Граффити футболка",i = 6877956799,s = 25.0,p = 450 },{ n = "Nike Hoodie",i = 4746292577,s = 22.0,p = 1800 },{ n = "Рваные джинсы",i = 15617408766,s = 20.0,p = 550 },{ n = "Gutta Opiu Black",i = 103809820683913,s = 10.0,p = 1000 },{ n = "Gutta Coffee Longsleeve",i = 131637613314592,s = 6.0,p = 1800 },{ n = "Amiri Худи Зеленое",i = 113811400216537,s = 3.0,p = 11000 },{ n = "Amiri Футболка Paint",i = 128351870809134,s = 1.5,p = 7500 },}}]=],
    ["Rare"] = [=[{["Rare"] = { { n = "Rick Owens Zip",i = 92750199062144,s = 25.0,p = 18500 },{ n = "Rick Owens Штаны",i = 14220615409,s = 22.0,p = 22000 },{ n = "BAPE Camo",i = 3131452093,s = 20.0,p = 4500 },{ n = "BAPE Camo штаны",i = 4947216628,s = 20.0,p = 3800 },{ n = "Carhartt Detroit Jacket",i = 1352050969,s = 20.0,p = 3500 },{ n = "Gutta Hoodie Black",i = 73257106599901,s = 20.0,p = 3200 },{ n = "Rick Owens Джинсы",i = 18477705722,s = 20.0,p = 25000 },{ n = "Gutta Hoodie Grey",i = 6877956799,s = 18.0,p = 3200 },{ n = "Nike Tech",i = 11554103603,s = 16.0,p = 2800 },{ n = "Palace Hoodie",i = 6174845177,s = 16.0,p = 4800 },{ n = "Stussy 8 Ball Hoodie",i = 6174845177,s = 16.0,p = 3800 },{ n = "Supreme Box Logo",i = 1499082681,s = 15.0,p = 12000 },{ n = "BAPE Shark",i = 94733728494733,s = 14.0,p = 6200 },{ n = "Burberry Classic",i = 14182270450,s = 14.0,p = 11000 },{ n = "Burberry Штаны",i = 16218939509,s = 14.0,p = 12500 },{ n = "Carhartt Cargo",i = 9367316394,s = 14.0,p = 3800 },{ n = "Cav Empt Свитшот Черный",i = 124139147116818,s = 14.0,p = 4500 },{ n = "Palm Angels Классик",i = 18660217283,s = 14.0,p = 12000 },{ n = "Palm Angels Серые",i = 10468675783,s = 14.0,p = 12000 },{ n = "Stone Island Default",i = 16388179108,s = 14.0,p = 14500 },{ n = "Stone Island Default",i = 15177463566,s = 14.0,p = 14500 },{ n = "Acne Studios Face Tee",i = 1352050969,s = 12.0,p = 9500 },{ n = "Amiri Футболка Черная",i = 18694595667,s = 12.0,p = 5500 },{ n = "CP.Company Default Pants",i = 6664977420,s = 12.0,p = 12500 },{ n = "Carhartt Shirt Jacket",i = 114724377,s = 12.0,p = 4200 },{ n = "Nike Tech Pants",i = 11410851476,s = 12.0,p = 3200 },{ n = "Palm Angels",i = 85991896636316,s = 12.0,p = 14500 },{ n = "Stussy Nylon Pants",i = 9367316394,s = 12.0,p = 4000 },{ n = "Supreme Pants",i = 7092331508,s = 12.0,p = 6500 },{ n = "Гоша Рубчинский Base",i = 15056443139,s = 12.0,p = 9500 },{ n = "Stone Island Joggers",i = 120383454886093,s = 11.0,p = 16500 },{ n = "CP.Company Свитшот",i = 14077919304,s = 10.0,p = 16500 },{ n = "Gallery Dept Спортивки Черные",i = 13974345356,s = 10.0,p = 4500 },{ n = "Palace Cargo",i = 9367316394,s = 10.0,p = 4500 },{ n = "Гоша Рубчинский x Fila",i = 438195463,s = 10.0,p = 12000 },{ n = "CP.Company Rose",i = 125295721091210,s = 9.0,p = 15500 },{ n = "NeNet Футболка Черная",i = 134937339779999,s = 9.0,p = 4500 },{ n = "Black Milo Shark Tee",i = 4695588521,s = 8.0,p = 7800 },{ n = "CP.Company Blue Hoodie",i = 16974592422,s = 8.0,p = 17500 },{ n = "CP.Company Gray Pants",i = 15783604661,s = 8.0,p = 19500 },{ n = "Comme des Garcons Футболка",i = 14582695300,s = 8.0,p = 11000 },{ n = "Drip футболка",i = 6384915788,s = 8.0,p = 1200 },{ n = "Gallery Dept Спортивки Голубой",i = 93556375284974,s = 8.0,p = 4200 },{ n = "Gallery Dept Спортивки Серые",i = 12792854135,s = 8.0,p = 4200 },{ n = "Gutta Zip-Hoodie",i = 87059217590619,s = 8.0,p = 3800 },{ n = "Nike Air Pants",i = 14343129826,s = 7.0,p = 4200 },{ n = "CP.Company Short Yellow",i = 13476230890,s = 6.0,p = 16000 },{ n = "NeNet Футболка Черный v2",i = 15015469155,s = 6.0,p = 4800 },{ n = "Nenet Штаны",i = 70880619395363,s = 6.0,p = 3800 },{ n = "CP.Company Blue Pants",i = 14050651166,s = 5.0,p = 21000 },{ n = "Designer джинсы",i = 18391376326,s = 5.0,p = 1400 },{ n = "NeNet Футболка Белая",i = 12089573241,s = 5.0,p = 5200 },{ n = "Racer WorldWide Свитшот",i = 11831115149,s = 3.5,p = 14500 },{ n = "Stone Island Свитшот",i = 1315352916,s = 3.5,p = 32000 },{ n = "Gallery Dept Спортивки Бежевый",i = 128614066781001,s = 3.0,p = 6500 },{ n = "Gallery Dept Спортивки Розовая",i = 99632820598737,s = 3.0,p = 6500 },{ n = "Racer WorldWide Свитшот Красный",i = 78683849537161,s = 3.0,p = 14500 },{ n = "BAPE Футболка",i = 105402915829012,s = 2.5,p = 5500 },{ n = "Gutta Black-White Longsleeve",i = 75730721795242,s = 2.5,p = 2800 },{ n = "Racer WorldWide Aphex Футболка",i = 16579558789,s = 1.8,p = 9500 },}}]=],
    ["Epic"] = [=[{["Epic"] = { { n = "Vetements Лонгслив",i = 95060430454867,s = 18.0,p = 13000 },{ n = "Chrome Hearts Logo White",i = 14502536751,s = 15.0,p = 24000 },{ n = "Maison Margiela Светлые Джинсы",i = 104326582321744,s = 15.0,p = 45000 },{ n = "Prada Cargo",i = 8425198358,s = 15.0,p = 42000 },{ n = "Prada Linea Rossa",i = 6174845177,s = 15.0,p = 38000 },{ n = "Rick Owens Футболка",i = 82934586126898,s = 15.0,p = 28000 },{ n = "CP.Company Orange Майка",i = 81270251381720,s = 12.0,p = 11500 },{ n = "Gucci Logo Tee",i = 2464334422,s = 12.0,p = 32000 },{ n = "Rick Drkshdw Pants",i = 12517077399,s = 12.0,p = 38000 },{ n = "Rick Owens DRKSHDW",i = 15422438906,s = 12.0,p = 35000 },{ n = "CP.Company Blanc Майка",i = 74448709325820,s = 11.0,p = 11500 },{ n = "Balenciaga Logo Print Tee",i = 124231377168467,s = 10.0,p = 24000 },{ n = "Chrome Hearts Tee Black",i = 134619700442692,s = 10.0,p = 36000 },{ n = "Gucci Sweatshirt Tiger",i = 2672925839,s = 10.0,p = 28000 },{ n = "LV Jeans",i = 15292591748,s = 10.0,p = 34000 },{ n = "LV Shirts",i = 135386999852550,s = 10.0,p = 32000 },{ n = "Rick Owens Джинсовка",i = 98599150857223,s = 10.0,p = 50000 },{ n = "Balenciaga Logo",i = 11386091941,s = 8.0,p = 28000 },{ n = "Cav Empt Зип-Худи",i = 2944205656,s = 8.0,p = 6200 },{ n = "Chrome Hearts Blue",i = 15705156210,s = 8.0,p = 32000 },{ n = "Gallery Dept Футболка Белый",i = 13835053077,s = 8.0,p = 5200 },{ n = "Gallery Dept Футболка Черная",i = 11725889271,s = 8.0,p = 4800 },{ n = "Gucci Lamb",i = 5023083383,s = 8.0,p = 34000 },{ n = "Gucci shorts x Blue Lubz",i = 5634486976,s = 8.0,p = 36000 },{ n = "Moncler Black Polo",i = 10793538519,s = 8.0,p = 26000 },{ n = "Moncler Tech Pants",i = 11382056477,s = 8.0,p = 28000 },{ n = "Moncler White Polo",i = 80707179561942,s = 8.0,p = 26000 },{ n = "Rick Owens Джинсовка Черная",i = 136218865674437,s = 8.0,p = 55000 },{ n = "Rick Owens Джинсы Зип",i = 89501380293235,s = 8.0,p = 45000 },{ n = "Supreme Свитшот",i = 3463183841,s = 8.0,p = 18500 },{ n = "Vetements Лонгслив Черный",i = 91606294899206,s = 8.0,p = 26000 },{ n = "Vetements Худи",i = 18983373539,s = 8.0,p = 20000 },{ n = "Maison Margiela Лонгслив Белая",i = 108337687172395,s = 7.0,p = 57000 },{ n = "Maison Margiela Лонгслив Черный",i = 138263043704514,s = 7.0,p = 57000 },{ n = "Vetements Худи Черное",i = 81560105275312,s = 7.0,p = 26000 },{ n = "1017 ALYX 9SM Футболка Белая",i = 13607073567,s = 6.0,p = 9000 },{ n = "Cav Empt Chemical Engineering",i = 3652598277,s = 6.0,p = 8500 },{ n = "Gucci LOVE",i = 956388277,s = 6.0,p = 36000 },{ n = "Moncler Big Logo",i = 11998504162,s = 6.0,p = 32000 },{ n = "Moncler Yellow Mini Puffer",i = 8171196077,s = 6.0,p = 28000 },{ n = "Off-White Черная",i = 4464224771,s = 6.0,p = 18500 },{ n = "Palm Angels Bear",i = 7724732726,s = 6.0,p = 16000 },{ n = "Rick Owens Джинсовка Синяя",i = 77234120970244,s = 6.0,p = 60000 },{ n = "Vetements Vamp Футболка",i = 86185820213136,s = 6.0,p = 34000 },{ n = "Гоша Рубчинский Flag",i = 5809785846,s = 6.0,p = 18500 },{ n = "Гоша Рубчинский Белая Футболка",i = 1435177629,s = 6.0,p = 9500 },{ n = "Off-White Белая Футболка",i = 111494454911134,s = 5.5,p = 18500 },{ n = "1017 ALYX 9SM Свитшот",i = 12014837061,s = 5.0,p = 10000 },{ n = "Acne Studios Jeans",i = 8425198358,s = 5.0,p = 22000 },{ n = "BAPE Shark Фиолетовая",i = 120028188529902,s = 5.0,p = 8800 },{ n = "BAPE Tiger Фиолетовый",i = 132534299493006,s = 5.0,p = 8500 },{ n = "CP.Company Noir Default",i = 87883117918210,s = 5.0,p = 22000 },{ n = "Cav Empt Свитшот Черный v2",i = 132771012378737,s = 5.0,p = 7200 },{ n = "Maison Margiela Свитер",i = 18270211852,s = 5.0,p = 92000 },{ n = "Moncler Black Full Sleeve",i = 3163582983,s = 5.0,p = 32000 },{ n = "Moncler Classic Pants",i = 80212103951429,s = 5.0,p = 34000 },{ n = "Moncler Vest Orange",i = 8162777342,s = 5.0,p = 34000 },{ n = "NeNet Свитшот",i = 129051289938686,s = 5.0,p = 9500 },{ n = "Rick Owens Штаны X Champion",i = 85545557857293,s = 5.0,p = 55000 },{ n = "BAPE Holographic Tiger Черная",i = 84803613886580,s = 4.5,p = 9500 },{ n = "Palm Angels Zip Классик",i = 15161522231,s = 4.5,p = 24000 },{ n = "Stone Island Gray Pants",i = 13781107752,s = 4.5,p = 28000 },{ n = "BAPE Зеленый/Оранжевый Tiger Белый",i = 127813886164608,s = 4.0,p = 7800 },{ n = "Burberry London",i = 14961358306,s = 4.0,p = 26000 },{ n = "Cav Empt Свитшот Серый",i = 139626993726125,s = 4.0,p = 9500 },{ n = "Comme des Garcons Camo Футболка",i = 5575894980,s = 4.0,p = 12500 },{ n = "Comme des Garcons Свитшот Серый",i = 11602203772,s = 4.0,p = 18500 },{ n = "Gallery Dept Футболка Зеленая",i = 101110457561961,s = 4.0,p = 4800 },{ n = "HBA Морф",i = 16452154247,s = 4.0,p = 12000 },{ n = "Moncler Black Jacket Alt",i = 5964807969,s = 4.0,p = 34000 },{ n = "Moncler Orange Jacket",i = 5960853118,s = 4.0,p = 34000 },{ n = "Moncler Yellow Puffer",i = 8162975494,s = 4.0,p = 34000 },{ n = "NeNet Свитшот Синий",i = 126688679972643,s = 4.0,p = 12000 },{ n = "Palm Angels Zip Серая",i = 15616127684,s = 4.0,p = 26000 },{ n = "Stussy World Tour",i = 114724377,s = 4.0,p = 7200 },{ n = "Vetements Лонгслив Темно-Синий",i = 99150978070886,s = 4.0,p = 26000 },{ n = "Acne Studios Oversized Hoodie",i = 6174845177,s = 3.5,p = 28000 },{ n = "BAPE Tiger Colors Черный",i = 74566614556041,s = 3.5,p = 8200 },{ n = "BAPE Tiger Red",i = 2783959084,s = 3.5,p = 11500 },{ n = "Comme des Garcons Лонгслив Белый-Черный",i = 5699364090,s = 3.5,p = 14500 },{ n = "Nike Tech Blue",i = 11554264756,s = 3.5,p = 4800 },{ n = "1017 ALYX 9SM Рубашка",i = 116739608201251,s = 3.0,p = 18000 },{ n = "Bape Tiger Зеленый/Оранжевый",i = 107348845353432,s = 3.0,p = 9200 },{ n = "Gallery Dept Лонгслив",i = 71091220191588,s = 3.0,p = 6200 },{ n = "Goyard Джинсы",i = 1226570804,s = 3.0,p = 55000 },{ n = "Goyard Джинсы v2",i = 993568649,s = 3.0,p = 58000 },{ n = "Moncler Green Jacket",i = 6722978612,s = 3.0,p = 34000 },{ n = "NeNet Свитшот Черный",i = 124013704220310,s = 3.0,p = 10500 },{ n = "Off-White Синяя",i = 2744313464,s = 3.0,p = 24000 },{ n = "Palace x Adidas",i = 114724377,s = 3.0,p = 9500 },{ n = "Palm Angels Zip",i = 5973979386,s = 3.0,p = 22000 },{ n = "Palm Angels Футболка Bear",i = 12257396304,s = 3.0,p = 18000 },{ n = "BAPE Dubai Camo Shark Белый",i = 79138012674866,s = 2.5,p = 11000 },{ n = "Gallery Dept Футболка",i = 101869006032601,s = 2.5,p = 5200 },{ n = "Gallery Dept Футболка Синяя",i = 125540636897982,s = 2.5,p = 5500 },{ n = "Supreme x ASAP",i = 431730384,s = 2.5,p = 32000 },{ n = "Yohji Yamamoto Спортивная Куртка Poison",i = 14606133245,s = 2.5,p = 38000 },{ n = "1017 ALYX 9SM x Moncler Свитшот",i = 14307549017,s = 2.0,p = 18000 },{ n = "1017 ALYX 9SM Свитшот Красный",i = 10253718453,s = 2.0,p = 18000 },{ n = "BAPE Panda Фиолетовый камуфляж",i = 96225370149582,s = 2.0,p = 9800 },{ n = "Balenciaga Tiger",i = 88020456613700,s = 2.0,p = 36000 },{ n = "Goyard Классическая Футболка",i = 907988303,s = 2.0,p = 48000 },{ n = "Goyard Классическая Футболка v2",i = 6131796962,s = 2.0,p = 48000 },{ n = "HBA Face Свитшот",i = 101719618368646,s = 2.0,p = 14000 },{ n = "HBA Face Шорты",i = 18588053395,s = 2.0,p = 14000 },{ n = "HBA Зип-Худи",i = 18588070468,s = 2.0,p = 13000 },{ n = "NeNet Футболка Белая v2",i = 83631847906705,s = 2.0,p = 11000 },{ n = "Vetements Худи v2",i = 107557100704001,s = 2.0,p = 42000 },{ n = "Гоша Рубчинский Футбол",i = 4909082176,s = 2.0,p = 22000 },{ n = "BAPE x Stussy",i = 836376693,s = 1.8,p = 15000 },{ n = "Gallery Dept Спортивки Серые v2",i = 112068921354030,s = 1.5,p = 9000 },{ n = "HBA Aphex Свитшот",i = 16579558789,s = 1.5,p = 16000 },{ n = "Nike Tech Blue",i = 12757775222,s = 1.5,p = 6500 },{ n = "Stone Island Termo Longsleave",i = 13948309746,s = 1.5,p = 42000 },{ n = "Золотая цепь",i = 12001043365,s = 1.5,p = 3800 },{ n = "BAPE Hellstar",i = 15059936417,s = 1.2,p = 12500 },{ n = "Racer WorldWide Свитер В Полоску",i = 8633623320,s = 1.2,p = 24000 },{ n = "Yohji Yamamoto Свитшот Зеленый",i = 7023449511,s = 1.0,p = 65000 },{ n = "Yohji Yamamoto Свитшот",i = 137788979820718,s = 0.8,p = 115000 },{ n = "CP.Company DD Shell Noir",i = 95337445087298,s = 0.7,p = 45000 },{ n = "AmiriKing",i = 73216590459166,s = 0.0,p = 220000 },}}]=],
    ["Legendary"] = [=[{["Legendary"] = { { n = "ERD Потертые Джинсы v1",i = 137773512709519,s = 14.0,p = 55000 },{ n = "Number(N)ine Черные Джинсы",i = 18323948106,s = 14.0,p = 55000 },{ n = "Vetements Джинсы Потертые",i = 87891411586632,s = 14.0,p = 20000 },{ n = "Vetements Спортивки Белые",i = 132566833184808,s = 14.0,p = 16000 },{ n = "ERD Белый Лонг",i = 105198371812252,s = 12.0,p = 38000 },{ n = "Chrome Hearts Sweats Black",i = 92049531048374,s = 10.0,p = 38000 },{ n = "ERD Лонгслив",i = 76738452087604,s = 10.0,p = 45000 },{ n = "Number(N)ine Коричневое Худи",i = 18632819241,s = 10.0,p = 92000 },{ n = "Number(N)ine Красный Лонгслив",i = 128716647842609,s = 10.0,p = 62000 },{ n = "Vetements Синие-Джинсы Потертые",i = 126970846706113,s = 10.0,p = 24000 },{ n = "Vetements Спортивки Черный",i = 80693415563613,s = 10.0,p = 16000 },{ n = "Chrome Hearts Basic Tee",i = 16582495088,s = 8.0,p = 28000 },{ n = "Dior Зип",i = 10371714775,s = 8.0,p = 72000 },{ n = "Dior Зип Худи",i = 85583075418361,s = 8.0,p = 72000 },{ n = "Dior Лонгслив",i = 101488585369119,s = 8.0,p = 72000 },{ n = "Dior Свитер",i = 118344538644973,s = 8.0,p = 72000 },{ n = "Dior Свитшот",i = 18147277043,s = 8.0,p = 72000 },{ n = "Dior Футболка",i = 18370037060,s = 8.0,p = 72000 },{ n = "Dior Худи",i = 122763783050786,s = 8.0,p = 72000 },{ n = "Prada Re-Nylon Jacket",i = 1352050969,s = 8.0,p = 72000 },{ n = "Chrome Hearts Grunge",i = 18968804462,s = 6.0,p = 45000 },{ n = "Chrome Hearts Rainbow Cross",i = 10322816406,s = 6.0,p = 42000 },{ n = "Chrome Hearts Tee",i = 73657715280895,s = 6.0,p = 32000 },{ n = "Comme des Garcons Футболка Черная",i = 15121388536,s = 6.0,p = 8000 },{ n = "Gucci Polo Shake",i = 5469366412,s = 6.0,p = 38000 },{ n = "Raf Simons Replicant Черный",i = 131319439176543,s = 6.0,p = 62000 },{ n = "Vetements Футболка Оранжевая",i = 80547880319610,s = 6.0,p = 36000 },{ n = "Balenciaga Jeans",i = 122599601118964,s = 5.0,p = 38000 },{ n = "CP.Company Cardigan Black",i = 99737839478071,s = 5.0,p = 24000 },{ n = "Chrome Hearts Cyan Alt",i = 6447552174,s = 5.0,p = 38000 },{ n = "Chrome Hearts Jeans",i = 15696366780,s = 5.0,p = 38000 },{ n = "Chrome Hearts Red Shirt",i = 99324171797960,s = 5.0,p = 34000 },{ n = "Chrome Hearts Zip Up Black",i = 6198234501,s = 5.0,p = 52000 },{ n = "Chrome Hearts Zip Up Hoodie Black",i = 18400219191,s = 5.0,p = 34000 },{ n = "ERD Потертые Джинсы v2",i = 83641705983017,s = 5.0,p = 8000 },{ n = "Maison Margiela Зеленый Лонгслив",i = 73388686842934,s = 5.0,p = 65532 },{ n = "Number(N)ine Потертые Джинсы",i = 102839033215257,s = 5.0,p = 42000 },{ n = "Number(N)ine Серое Худи",i = 18632881209,s = 5.0,p = 98000 },{ n = "Palm Angels Футболка v3",i = 11511640247,s = 5.0,p = 26000 },{ n = "Raf Simons Antei Purple",i = 116642119535875,s = 5.0,p = 48000 },{ n = "Vetements Футболка Зеленая Polizei",i = 90919421530654,s = 5.0,p = 30000 },{ n = "Yohji Yamamoto Брюки",i = 18606916311,s = 5.0,p = 78000 },{ n = "Гоша Рубчинский Свитер Синий",i = 9545499629,s = 5.0,p = 34000 },{ n = "Balenciaga Campaign",i = 10890916980,s = 4.0,p = 45000 },{ n = "Balenciaga Grey Jumper",i = 3785693796,s = 4.0,p = 34000 },{ n = "Chrome Hearts Blue Jeans",i = 7136404058,s = 4.0,p = 42000 },{ n = "Chrome Hearts Cyan",i = 14127820316,s = 4.0,p = 42000 },{ n = "Chrome Hearts Gray Denim Jeans",i = 16733661152,s = 4.0,p = 38000 },{ n = "Chrome Hearts Grey Jeans",i = 122714934882673,s = 4.0,p = 42000 },{ n = "Chrome Hearts Orange Sweater",i = 7381767636,s = 4.0,p = 42000 },{ n = "Comme des Garcons Футболка Love Белая",i = 2098915079,s = 4.0,p = 12000 },{ n = "Palm Angels Футболка v2",i = 127026922296813,s = 4.0,p = 28000 },{ n = "CP.Company Teal Jumper",i = 97526151621254,s = 3.5,p = 24000 },{ n = "Balenciaga Distressed Hoodie",i = 13676876569,s = 3.0,p = 28000 },{ n = "Balenciaga Hoodie Alien",i = 86463016923018,s = 3.0,p = 38000 },{ n = "Chrome Hearts Blue Jeans Chrome",i = 7902431231,s = 3.0,p = 24000 },{ n = "Chrome Hearts Multi Color Cargos",i = 16430470279,s = 3.0,p = 52000 },{ n = "Chrome Hearts Pink-Black Jeans",i = 10946069869,s = 3.0,p = 45000 },{ n = "Chrome Hearts Rainbow Sweatshirt",i = 116987323218059,s = 3.0,p = 45000 },{ n = "Chrome Hearts Red & Green Sweater",i = 77430172245334,s = 3.0,p = 38000 },{ n = "Chrome Hearts Red And Blue",i = 9026168986,s = 3.0,p = 28000 },{ n = "Chrome Hearts X LV Jeans",i = 7248675954,s = 3.0,p = 42000 },{ n = "Comme des Garcons Play Футболка Черная",i = 81585264094038,s = 3.0,p = 10000 },{ n = "Comme des Garcons Футболка Белый-Красный",i = 1079296706,s = 3.0,p = 10000 },{ n = "ERD Destroyed Hoodie",i = 124798507529638,s = 3.0,p = 92000 },{ n = "Gucci Star Sweater",i = 6181344251,s = 3.0,p = 42000 },{ n = "Gucci Tiger Tracksuit",i = 5680301087,s = 3.0,p = 72000 },{ n = "LV x TNF",i = 5836356644,s = 3.0,p = 62000 },{ n = "Maison Margiela Темные Джинсы",i = 81765716375958,s = 3.0,p = 49000 },{ n = "Off-White Белая Футболка v3",i = 138024345748614,s = 3.0,p = 32000 },{ n = "Raf Simons Ozweego 3 Black Scarlett",i = 112685667527061,s = 3.0,p = 68000 },{ n = "Raf Simons Ozweego 3 Bunny Cream",i = 72101896533425,s = 3.0,p = 65000 },{ n = "Raf Simons Ozweego Metallic Pink",i = 87554525526000,s = 3.0,p = 58000 },{ n = "Balenciaga Blue Skater Sweatpants",i = 124975585838444,s = 2.5,p = 45000 },{ n = "Balenciaga Grey Skater Sweatpants",i = 93824635464666,s = 2.5,p = 45000 },{ n = "Balenciaga Red Skater Sweatpants",i = 15732426819,s = 2.5,p = 45000 },{ n = "CP.Company Crewneck",i = 15783597851,s = 2.5,p = 28000 },{ n = "Chrome Hearts Gray Sweater",i = 6678207951,s = 2.5,p = 62000 },{ n = "Chrome Hearts Red Jeans",i = 15167783027,s = 2.5,p = 45000 },{ n = "Off-White Белая Футболка v2",i = 4809072541,s = 2.5,p = 32000 },{ n = "Off-White Черная Футболка v2",i = 15084872864,s = 2.5,p = 32000 },{ n = "Balenciaga Logo Print Hoodie Blue",i = 15825720946,s = 2.0,p = 48000 },{ n = "Balenciaga Under Armor",i = 109107120274465,s = 2.0,p = 52000 },{ n = "Balenciaga X Under Armor",i = 17747885612,s = 2.0,p = 38000 },{ n = "Balenciaga x Fortnite",i = 102510983142980,s = 2.0,p = 62000 },{ n = "Chrome Hearts Orange Pants",i = 7548737358,s = 2.0,p = 48000 },{ n = "Chrome Hearts Yellow Hoodie",i = 11454813848,s = 2.0,p = 62000 },{ n = "ERD Vintage Washed Hoodie",i = 6384915788,s = 2.0,p = 110000 },{ n = "Gucci X Tee",i = 3370349046,s = 2.0,p = 62000 },{ n = "LV Balmains",i = 967030317,s = 2.0,p = 72000 },{ n = "Maison Margiela Рубашка",i = 135517402543302,s = 2.0,p = 62000 },{ n = "Moncler Gray Sweater",i = 5341316038,s = 2.0,p = 36000 },{ n = "Moncler Gray Vest",i = 6142390595,s = 2.0,p = 38000 },{ n = "Moncler Red Puffer",i = 6455447834,s = 2.0,p = 38000 },{ n = "Moncler Red Tracksuit Bottom",i = 6488509571,s = 2.0,p = 36000 },{ n = "Moncler Vest Classic",i = 6488586232,s = 2.0,p = 36000 },{ n = "Number(N)ine Винтажная Футболка",i = 6384915788,s = 2.0,p = 110000 },{ n = "Number(N)ine Черный Лонгслив",i = 12274864979,s = 2.0,p = 110000 },{ n = "Raf Simons Cylon 21 Red",i = 75354435184240,s = 2.0,p = 70000 },{ n = "Raf Simons Ozweego 2 Yellow Navy",i = 84478752542723,s = 2.0,p = 58000 },{ n = "Raf Simons Ultrasceptre Black",i = 76698897803837,s = 2.0,p = 65000 },{ n = "Raf Simons Поло Красное",i = 76516442021518,s = 2.0,p = 45000 },{ n = "Rick Owens x Moncler",i = 8573407398,s = 2.0,p = 95000 },{ n = "Rick Owens Джинсы Розовые",i = 84825703583648,s = 2.0,p = 85000 },{ n = "Stone Island Navy",i = 831537199,s = 2.0,p = 34000 },{ n = "Гоша Рубчинский Свитер Зелёный",i = 5549063618,s = 2.0,p = 25000 },{ n = "Balenciaga Paris Moon Sweater",i = 4590342423,s = 1.5,p = 42000 },{ n = "Balenciaga Speed Runner Hoodie",i = 15453420630,s = 1.5,p = 55000 },{ n = "Balenciaga x Gucci",i = 3138759121,s = 1.5,p = 72000 },{ n = "Cav Empt Футболка Spring Delivery",i = 2887711548,s = 1.5,p = 14000 },{ n = "Comme des Garcons Лонгслив Белый-Синий",i = 962194504,s = 1.5,p = 14000 },{ n = "ERD Bully Худи",i = 128216714278616,s = 1.5,p = 110000 },{ n = "Gallery Dept Красный Зип-Худи",i = 86921710360798,s = 1.5,p = 7500 },{ n = "Gucci Sweatshirt Planet",i = 1083553649,s = 1.5,p = 58000 },{ n = "Moncler Black Jacket",i = 9375216039,s = 1.5,p = 38000 },{ n = "Moncler Black Tracksuit Bottom",i = 15338842173,s = 1.5,p = 42000 },{ n = "Moncler Puffer Logo",i = 6488495469,s = 1.5,p = 45000 },{ n = "Moncler Red Tracksuit",i = 6488509571,s = 1.5,p = 42000 },{ n = "Moncler TriColor Windbreaker",i = 4831711976,s = 1.5,p = 42000 },{ n = "Number(N)ine Shield Серое Худи",i = 105478169140045,s = 1.5,p = 140000 },{ n = "Number(N)ine Футболка",i = 14885532636,s = 1.5,p = 150000 },{ n = "Palm Angels Свитшот Голубой",i = 6274614487,s = 1.5,p = 38000 },{ n = "Raf Simons Brian Calvin Beer Girl",i = 75216977300015,s = 1.5,p = 135000 },{ n = "Raf Simons Hoodie",i = 15570425245,s = 1.5,p = 150000 },{ n = "Raf Simons Ozweego 2 Blue Red Lucora",i = 70728690346102,s = 1.5,p = 75000 },{ n = "Raf Simons Ozweego 2 Gray Green",i = 105222831634134,s = 1.5,p = 68000 },{ n = "Raf Simons Ozweego 2 Khaki Gold",i = 124039750585318,s = 1.5,p = 120000 },{ n = "Raf Simons Худи Серый",i = 102589072483955,s = 1.5,p = 68000 },{ n = "Rick Owens Джинсовка Красная",i = 71424043928165,s = 1.5,p = 110000 },{ n = "Stone Island Orange",i = 14840856758,s = 1.5,p = 38000 },{ n = "Stone Island Pink",i = 14984408119,s = 1.5,p = 38000 },{ n = "Vetements Antwerpen Белая v2",i = 15564674144,s = 1.5,p = 34000 },{ n = "Гоша Рубчинский Вдруг Красный",i = 2118764687,s = 1.5,p = 26000 },{ n = "Гоша Рубчинский Враг Свитер Черный",i = 5487023113,s = 1.5,p = 28000 },{ n = "Comme des Garcons Футболка Camo Love",i = 8128676575,s = 1.2,p = 16000 },{ n = "Off-White Зеленый",i = 3224293759,s = 1.2,p = 42000 },{ n = "Palm Angels Zip Красная",i = 126190832806951,s = 1.2,p = 42000 },{ n = "Rick Owens Джинсовка Желтая",i = 130104280419383,s = 1.2,p = 115000 },{ n = "Stone Island Zip-Hoodie",i = 87509417534862,s = 1.2,p = 48000 },{ n = "Гоша Рубчинский Zip Красный/Синий",i = 4996937439,s = 1.2,p = 24000 },{ n = "Balenciaga Runway Polo Hoodie",i = 85720763562074,s = 1.0,p = 72000 },{ n = "Balenciaga Tokyo Cut",i = 98869180278083,s = 1.0,p = 52000 },{ n = "Chrome Hearts Cross Patch Dog",i = 90412503682792,s = 1.0,p = 72000 },{ n = "Chrome Hearts Matty Boy Space",i = 18428381654,s = 1.0,p = 95000 },{ n = "Chrome Hearts Matty Boy Sweatshirt",i = 126863028392369,s = 1.0,p = 98000 },{ n = "Chrome Hearts Rolling Stones",i = 85305185315542,s = 1.0,p = 72000 },{ n = "ERD Skull Denim Jacket",i = 114724377,s = 1.0,p = 140000 },{ n = "ERD Голубой Лонгслив",i = 102885674981104,s = 1.0,p = 150000 },{ n = "Gucci Blind For Love Hoodie",i = 126913643075376,s = 1.0,p = 72000 },{ n = "Moncler Black Tapered Tracksuit",i = 15338842173,s = 1.0,p = 52000 },{ n = "Moncler Blue Coat",i = 9384199616,s = 1.0,p = 58000 },{ n = "Moncler Blue Zip-Up",i = 6505230129,s = 1.0,p = 60000 },{ n = "Moncler Maroon Jacket",i = 6787299892,s = 1.0,p = 62000 },{ n = "Moncler Parka Coat",i = 8446274549,s = 1.0,p = 55000 },{ n = "Moncler x Palm Angels Black",i = 13876237691,s = 1.0,p = 48000 },{ n = "Moncler x Palm Angels Jacket",i = 8165648360,s = 1.0,p = 58000 },{ n = "Moncler x Palm Angels Red Zip",i = 5964876806,s = 1.0,p = 58000 },{ n = "Off-White Бежевая",i = 590131471,s = 1.0,p = 48000 },{ n = "Raf Simons Ozweego Replicant Brown",i = 131686044597910,s = 1.0,p = 58000 },{ n = "Raf Simons Ozweego Replicant Green",i = 109462627025831,s = 1.0,p = 62000 },{ n = "Raf Simons Красный Лонгслив",i = 125538194046026,s = 1.0,p = 98000 },{ n = "Raf Simons Красный Лонгслив v2",i = 140534031809179,s = 1.0,p = 82000 },{ n = "Rick Leather",i = 101535348409637,s = 1.0,p = 125000 },{ n = "Vetements Antwerp Красный",i = 18720565335,s = 1.0,p = 34000 },{ n = "Vetements Antwerpen Белая v1",i = 124697147814478,s = 1.0,p = 34000 },{ n = "Yohji Yamamoto Project Футболка",i = 89357762722807,s = 1.0,p = 45000 },{ n = "Гоша Рубчинский Гибридный",i = 14578854678,s = 1.0,p = 32000 },{ n = "Yohji Yamamoto Свитшот Supreme",i = 130582847343989,s = 0.9,p = 92000 },{ n = "1017 ALYX 9SM Куртка Зип",i = 16949566103,s = 0.8,p = 22000 },{ n = "Balenciaga 3B Sports Deutsche Bahn",i = 137408844484403,s = 0.8,p = 72000 },{ n = "CP.Company Blue Puffer Jacket",i = 82077729005226,s = 0.8,p = 52000 },{ n = "Gallery Dept Свитшот Синий",i = 79423109019674,s = 0.8,p = 14500 },{ n = "Moncler X PA Trackpants",i = 5459824253,s = 0.8,p = 52000 },{ n = "Polo Burberry",i = 15903662503,s = 0.8,p = 42000 },{ n = "Rick Owens Зип Джинсовка Розовая",i = 121618494628389,s = 0.8,p = 135000 },{ n = "Stone Island Desert Camo",i = 8462301101,s = 0.8,p = 45000 },{ n = "Stone Island Turtleneck",i = 12624379885,s = 0.8,p = 55000 },{ n = "Supreme x BB",i = 13444831702,s = 0.8,p = 28000 },{ n = "Vetements Antwerp Темно-Красное",i = 4552458072,s = 0.8,p = 34000 },{ n = "Vetements Зип-Худи",i = 128389783148999,s = 0.8,p = 72000 },{ n = "Гоша Рубчинский Fila Yellow LS",i = 87503337904060,s = 0.8,p = 32000 },{ n = "Гоша Рубчинский Спорт Куртка Russian",i = 607550981,s = 0.8,p = 32000 },{ n = "Off-White Свитер",i = 2518177916,s = 0.7,p = 58000 },{ n = "Гоша Рубчинский X Kappa Свитер",i = 15311273900,s = 0.7,p = 36000 },{ n = "Acne Studios Jacket",i = 114724377,s = 0.6,p = 68000 },{ n = "CP.Company Carbone Noir",i = 134908184079208,s = 0.6,p = 42000 },{ n = "Cav Empt Свитшот Желтый Symptom Heavy",i = 3244925440,s = 0.6,p = 18500 },{ n = "NeNet Футболка Серая",i = 118840925833484,s = 0.6,p = 22000 },{ n = "Stone Island Urban Black Yellow",i = 7249098507,s = 0.6,p = 62000 },{ n = "Yohji Yamamoto AW 2001 Godzilla Свитшот",i = 4794620897,s = 0.6,p = 95000 },{ n = "Гоша Рубчинский Худи ColorBrick",i = 560325377,s = 0.6,p = 38000 },{ n = "BAPE Red Panda",i = 85037105009809,s = 0.5,p = 18000 },{ n = "BAPE Tiger Штаны Красные",i = 137022318888712,s = 0.5,p = 24000 },{ n = "BAPE Tiger Штаны Синие",i = 72015381801594,s = 0.5,p = 24000 },{ n = "Balenciaga GAMER",i = 12774350601,s = 0.5,p = 92000 },{ n = "Balenciaga Gamer Jeans",i = 14072460187,s = 0.5,p = 95000 },{ n = "Balenciaga Resort 2023",i = 16648534764,s = 0.5,p = 62000 },{ n = "Chrome Hearts Black Pink LS",i = 90915822594460,s = 0.5,p = 110000 },{ n = "Chrome Hearts Miami Hoodie",i = 12852126150,s = 0.5,p = 118000 },{ n = "Chrome Hearts Ryft Davis",i = 79285824675024,s = 0.5,p = 85000 },{ n = "Comme des Garcons Рубашка",i = 123772691907841,s = 0.5,p = 32000 },{ n = "ERD Distressed Zip Jacket",i = 12001043365,s = 0.5,p = 170000 },{ n = "ERD x Rick Owens Джинсы",i = 74573745510706,s = 0.5,p = 140000 },{ n = "ERD Красные Джинсы",i = 102019726797995,s = 0.5,p = 145000 },{ n = "Gallery Dept Lanvin",i = 87630874548849,s = 0.5,p = 32000 },{ n = "Goyard Зеленая Футболка",i = 6763195401,s = 0.5,p = 75000 },{ n = "Gucci Tiger Hoodie",i = 1518645608,s = 0.5,p = 135000 },{ n = "Gucci x LV Jacket",i = 2109554081,s = 0.5,p = 95000 },{ n = "HBA Creepy Свитшот",i = 93422277147402,s = 0.5,p = 32000 },{ n = "Moncler Green Zip-up",i = 6505230940,s = 0.5,p = 55000 },{ n = "Moncler Multi Colored Jacket",i = 3689506876,s = 0.5,p = 60000 },{ n = "Moncler Purple Bubble Jacket",i = 6455445003,s = 0.5,p = 72000 },{ n = "Moncler X PA Blue Tracksuit Bot",i = 12636365073,s = 0.5,p = 58000 },{ n = "Moncler X PA Blue Tracksuit Top",i = 12636365073,s = 0.5,p = 72000 },{ n = "Racer Worldwide Светлые Джинсы",i = 124377088956183,s = 0.5,p = 18000 },{ n = "Racer Worldwide Спортивные Штаны",i = 82685608298333,s = 0.5,p = 18000 },{ n = "Raf Simons Black Christiane F AW18",i = 91498176431445,s = 0.5,p = 92000 },{ n = "Raf Simons Brian Calvin Beer Girl Tee",i = 122313792956641,s = 0.5,p = 145000 },{ n = "Rick Owens Футболка Vamp",i = 83255075167663,s = 0.5,p = 150000 },{ n = "SS04 Yohji Yamamoto Y-3 x 3S Spotted Джинсы",i = 71399636217265,s = 0.5,p = 85000 },{ n = "Stone Island Desert Camo",i = 8631687945,s = 0.5,p = 52000 },{ n = "Supreme x LV",i = 5226567379,s = 0.5,p = 92000 },{ n = "Vetements 204 Hyoma Raf Reconstructed",i = 75624653597148,s = 0.5,p = 42000 },{ n = "Vetements Бомбер",i = 134508752165617,s = 0.5,p = 95000 },{ n = "Zapatillas Gucci X Amiri",i = 134853942496739,s = 0.5,p = 110000 },{ n = "Гоша Рубчинский x Kappa",i = 884721414,s = 0.5,p = 38000 },{ n = "BAPE Tiger Штаны Темно-Зелен",i = 131922684973046,s = 0.4,p = 26000 },{ n = "CP.Company DD Shell Green",i = 100997096188512,s = 0.4,p = 65000 },{ n = "CP.Company Orange Pants",i = 16974632408,s = 0.4,p = 48000 },{ n = "Comme des Garcons Синий Зип-Худи",i = 1074658737,s = 0.4,p = 28000 },{ n = "Gallery Dept Свитшот Коричневый",i = 118666889439649,s = 0.4,p = 11000 },{ n = "Gutta Raiders Camo shirt",i = 86664943903751,s = 0.4,p = 18000 },{ n = "Nike Tech Dark Blue",i = 15501893721,s = 0.4,p = 9500 },{ n = "Nike Tech Dark Light Blue",i = 8801995627,s = 0.4,p = 9500 },{ n = "Palm Angels Flame",i = 5611331869,s = 0.4,p = 52000 },{ n = "Racer Worldwide Металлик Спортивные Штаны",i = 75548914998494,s = 0.4,p = 34000 },{ n = "Vetements Anarchy",i = 17508312490,s = 0.4,p = 85000 },{ n = "Vetements Clothing Green",i = 77220484371723,s = 0.4,p = 82000 },{ n = "Yohji Yamamoto Ys for Men AW2001 Godzilla",i = 6046174032,s = 0.4,p = 135000 },{ n = "Yohji Yamamoto Свитшот Smoke",i = 8826223539,s = 0.4,p = 125000 },{ n = "Yohji Yamamoto Свитшот Spider Knit",i = 10515393675,s = 0.4,p = 98000 },{ n = "Гоша Рубчинский x Kappa",i = 1824185908,s = 0.4,p = 45000 },{ n = "Гоша Рубчинский x Kappa Винтаж",i = 1162019947,s = 0.4,p = 41000 },{ n = "Stone Island Off Day Blue",i = 117161695009647,s = 0.35,p = 72000 },{ n = "Stone Island Red Hoodie Off Dye",i = 97856390601463,s = 0.35,p = 68000 },{ n = "Гоша Рубчинский Флаги",i = 98305906232207,s = 0.35,p = 48000 },{ n = "BAPE Yellow Camo Shark",i = 4843433327,s = 0.3,p = 28000 },{ n = "Balenciaga GAMER Denim Jacket",i = 16648632315,s = 0.3,p = 115000 },{ n = "Balenciaga Red Crimson Windbreaker",i = 133873637543203,s = 0.3,p = 95000 },{ n = "CP.Company DD Shell Red",i = 78185107533537,s = 0.3,p = 75000 },{ n = "Chrome Hearts Multi-Colour Hoodie",i = 16919855258,s = 0.3,p = 125000 },{ n = "Gallery Dept Худи Зеленое",i = 140022990256816,s = 0.3,p = 18000 },{ n = "Gutta Snake Year",i = 70895461143874,s = 0.3,p = 15000 },{ n = "Moncler X PA FG Tracksuit Bot",i = 12621049095,s = 0.3,p = 62000 },{ n = "Moncler X PA Forest Green Bot",i = 12621050787,s = 0.3,p = 60000 },{ n = "Moncler X PA Forest Green Top",i = 12621049095,s = 0.3,p = 75000 },{ n = "Moncler x PA Puffer Jacket",i = 14396989921,s = 0.3,p = 85000 },{ n = "Number(N)ine Zip Jacket",i = 81231921426493,s = 0.3,p = 220000 },{ n = "Raf Simons Christiane F Tees AW18",i = 125655994023355,s = 0.3,p = 195000 },{ n = "Raf Simons Бомбер Белый",i = 86995497093030,s = 0.3,p = 160000 },{ n = "Rick Owens Runway",i = 8502567669,s = 0.3,p = 180000 },{ n = "Stone Island Desert Camo Jacket",i = 8631651981,s = 0.3,p = 72000 },{ n = "Yohji Yamamoto Rei Ayanami Evangelion Button up",i = 14484000414,s = 0.3,p = 145000 },{ n = "Yohji Yamamoto Свитшот Avant Garde",i = 86114857882709,s = 0.3,p = 155000 },{ n = "Yohji Yamamoto Свитшот Skull",i = 5166805206,s = 0.3,p = 110000 },{ n = "CP.Company Black Windbreaker",i = 113247621156859,s = 0.25,p = 88000 },{ n = "Off-White MonoLisa",i = 2474144253,s = 0.25,p = 75000 },{ n = "Palm Angels Фиолетовые",i = 9084664827,s = 0.25,p = 62000 },{ n = "Racer WorldWide Леопардовая Зип-Худи",i = 118245234493513,s = 0.25,p = 42000 },{ n = "Stone Island WATRO-TC",i = 8631779037,s = 0.25,p = 68000 },{ n = "Vetements Бомбер Зеленый",i = 89790335131378,s = 0.25,p = 110000 },{ n = "Vetements Бомбер Красный",i = 117766762488194,s = 0.25,p = 110000 },{ n = "Vetements Бомбер Тёмно-Зеленый",i = 77439910826532,s = 0.25,p = 110000 },{ n = "Yohji Yamamoto J-PT Иллюстрация",i = 129487569430492,s = 0.25,p = 115000 },{ n = "Balenciaga Jean Jacket X Gosha",i = 5314403333,s = 0.2,p = 110000 },{ n = "Burberry x Bape",i = 13868676222,s = 0.2,p = 68000 },{ n = "CP.Company DD Shell Beige",i = 139627508845654,s = 0.2,p = 78000 },{ n = "HBA Рубашка",i = 71222633992816,s = 0.2,p = 28000 },{ n = "Maison Margiela Женская Меховая Куртка",i = 137990594447175,s = 0.2,p = 100000 },{ n = "Moncler Striped Technical",i = 5029449227,s = 0.2,p = 95000 },{ n = "Гоша Рубчинский Camo Спаси Сохрани",i = 576444465,s = 0.2,p = 52000 },{ n = "Balenciaga GAMER Bomber",i = 17750429143,s = 0.15,p = 140000 },{ n = "CP.Company Navy Windbreaker",i = 131336649441063,s = 0.15,p = 92000 },{ n = "Cav Empt Not Impossible Crewneck",i = 322189906,s = 0.15,p = 12000 },{ n = "Comme des Garcons X Rolling Stones Футболка",i = 116168634401177,s = 0.15,p = 42000 },{ n = "NeNet Футболка Фиолетовая",i = 9930373240,s = 0.15,p = 38000 },{ n = "Number(N)ine Серая Zip Jacket",i = 99950858190570,s = 0.15,p = 245000 },{ n = "Off-White Camo",i = 1213373791,s = 0.15,p = 92000 },{ n = "Racer Worldwide Трансформ Зип Джинсы",i = 138030819896058,s = 0.15,p = 48000 },{ n = "Stone Island WATRO-TC Jacket",i = 8631755151,s = 0.15,p = 88000 },{ n = "Vetements Бомбер Полиция",i = 11290616980,s = 0.15,p = 135000 },{ n = "Yohji Yamamoto Heroes Leather Байкерская Куртка",i = 4895301337,s = 0.15,p = 185000 },{ n = "Гоша Рубчинский x Rassvet",i = 15706847548,s = 0.15,p = 45000 },{ n = "Balenciaga NASA",i = 97665782669251,s = 0.1,p = 140000 },{ n = "Balenciaga Reversible Bomber Jacket",i = 18813584989,s = 0.1,p = 150000 },{ n = "Cav Empt Свитшот MD Document Crewneck",i = 1002344605,s = 0.1,p = 16000 },{ n = "ERD Archive Trousers",i = 18391376326,s = 0.1,p = 220000 },{ n = "Moncler Spider",i = 11674658234,s = 0.1,p = 105000 },{ n = "Moncler x PA Kelsey Puffer Blue",i = 11484662835,s = 0.1,p = 110000 },{ n = "Raf Simons LSD White",i = 125293782853552,s = 0.1,p = 225000 },{ n = "Raf Simons SS10 Sterling Ruby Shirt",i = 95423048146621,s = 0.1,p = 280000 },{ n = "Stone Island Comfort Tech Blue",i = 118064352416891,s = 0.1,p = 75000 },{ n = "Stone Island Comfort Tech Red",i = 120903225671360,s = 0.1,p = 82000 },{ n = "Stone Island Reflective",i = 139421353405484,s = 0.1,p = 85000 },{ n = "Supreme x Bape x LV",i = 1565502112,s = 0.1,p = 140000 },{ n = "Yohji Yamamoto Зеленая Куртка",i = 115386784245524,s = 0.1,p = 88000 },{ n = "BAPE Tiger Штаны Фиолетовые",i = 99313817373559,s = 0.08,p = 38000 },{ n = "Gallery Dept Футболка Шамана",i = 100168311309116,s = 0.08,p = 28000 },{ n = "Racer WorldWide Куртка из Овечьи Шкуры",i = 99497707297997,s = 0.08,p = 68000 },{ n = "Stone Island Purple Skin Touch",i = 13779001426,s = 0.08,p = 85000 },{ n = "Stone Island Skin Touch Purple",i = 13778721268,s = 0.08,p = 98000 },{ n = "Cav Empt Свитшот Joker",i = 18280893525,s = 0.07,p = 22000 },{ n = "BAPE Tiger Camo",i = 3052304894,s = 0.06,p = 52000 },{ n = "Гоша Рубчинский Рождест",i = 11796928325,s = 0.06,p = 62000 },{ n = "Cav Empt Свитшот FW 17",i = 914784455,s = 0.05,p = 38000 },{ n = "Chrome Hearts Camo Matty",i = 72762590768448,s = 0.05,p = 190000 },{ n = "ERD Archive Лонгслив",i = 122273528955293,s = 0.05,p = 290000 },{ n = "ERD Archive Худи Красный",i = 98881995294054,s = 0.05,p = 310000 },{ n = "Nike Tech Windrunner Black",i = 7397565263,s = 0.05,p = 22000 },{ n = "Number(N)ine Серый Лонгслив",i = 17573405272,s = 0.05,p = 310000 },{ n = "Raf Simons 2-CB GHB Patchwork",i = 120612391944120,s = 0.05,p = 270000 },{ n = "Cav Empt Бомбер",i = 297942903,s = 0.04,p = 42000 },{ n = "Stone Island Shadow Tiger Camo",i = 132959748946564,s = 0.04,p = 125000 },{ n = "Гоша Рубчинский X Thrasher",i = 436720176,s = 0.04,p = 88000 },{ n = "Гоша Рубчинский Зеленый Свитер",i = 772695241,s = 0.03,p = 95000 },{ n = "Balenciaga Paris",i = 125248485368695,s = 0.02,p = 245000 },{ n = "Chrome Hearts T Logo USA Hoodie",i = 96585015209179,s = 0.02,p = 245000 },{ n = "ERD Красная Джинсовка",i = 120196252098729,s = 0.02,p = 450000 },{ n = "Gucci Coco Capitan",i = 1081054870,s = 0.02,p = 245000 },{ n = "Gutta Opiy Shirt",i = 75621017852847,s = 0.02,p = 52000 },{ n = "Palm Angels x Raf Blue Red",i = 88741221455613,s = 0.02,p = 110000 },{ n = "Stone Island Comfort Tech Purple",i = 119767338320263,s = 0.02,p = 145000 },{ n = "TH Hoodie X Balenciaga x RAF",i = 2074367265,s = 0.02,p = 220000 },{ n = "Racer WorldWide ЛонгСлив Катя Кищук",i = 97197585182330,s = 0.015,p = 125000 },{ n = "Гоша Рубчинский Вдруг Друг",i = 107248336623941,s = 0.015,p = 115000 },{ n = "Гоша Рубчинский Рождественский",i = 5972477579,s = 0.015,p = 115000 },{ n = "Balenciaga Leather",i = 84116395504704,s = 0.01,p = 320000 },{ n = "Balenciaga Nasa Bomber Jacket",i = 82170977556685,s = 0.01,p = 350000 },{ n = "Balenciaga Runway",i = 16662225397,s = 0.01,p = 300000 },{ n = "Chrome Hearts x Off-White Hoodie",i = 5944585429,s = 0.01,p = 320000 },{ n = "Number(N)ine Shield Черное Худи",i = 81895753471926,s = 0.01,p = 420000 },{ n = "Stone Island x Supreme",i = 84913974138865,s = 0.01,p = 115000 },{ n = "Stone Island x Supreme White",i = 108047896837515,s = 0.01,p = 115000 },{ n = "Palm Angels Zip Фиолетовый",i = 89385145596759,s = 0.009,p = 145000 },{ n = "Palm Angels Zip Цветок",i = 6501833600,s = 0.009,p = 145000 },{ n = "Stone Island x Supreme",i = 13876916079,s = 0.008,p = 165000 },{ n = "Stone Island x Supreme Белые",i = 139017627542362,s = 0.008,p = 165000 },{ n = "Bape x Supreme",i = 1103783724,s = 0.007,p = 125000 },{ n = "Palm Angels Zip Кислотный",i = 7205233886,s = 0.007,p = 155000 },{ n = "BAPE Full Zip Shark",i = 1329266704,s = 0.005,p = 135000 },{ n = "Chrome Hearts x LV Jacket",i = 7369775838,s = 0.005,p = 380000 },{ n = "Maison Margiela Куртка из Ремней",i = 122468912421457,s = 0.005,p = 120000 },{ n = "Moncler x PA Fiber Light Puffer",i = 13429337035,s = 0.005,p = 400000 },{ n = "Off-White Virgil Abloh Красный",i = 6071739662,s = 0.005,p = 285000 },{ n = "Raf Simons Pharaxus Green Black",i = 101604148293803,s = 0.005,p = 680000 },{ n = "Stone Island Big Loom Camo-Tc",i = 8631708424,s = 0.005,p = 280000 },{ n = "Yohji Yamamoto Свитшот Кожанка",i = 131596879156451,s = 0.005,p = 450000 },{ n = "Yohji Yamamoto Куртка Красная",i = 132752004376816,s = 0.004,p = 480000 },{ n = "Haliky Gang Bears",i = 6676412081,s = 0.003,p = 72000 },{ n = "Yohji Yamamoto Куртка Темно-Синяя",i = 90420982954859,s = 0.003,p = 520000 },{ n = "Raf Simons AW01 Runway",i = 10443560347,s = 0.002,p = 950000 },{ n = "Stone Island Big Loom Camo-Tc",i = 8631671234,s = 0.002,p = 350000 },{ n = "Haliky Худи",i = 6004029876,s = 0.001,p = 85000 },{ n = "Dior Джинсы",i = 139013853108228,s = 0.0,p = 0 },{ n = "Dior Шорты",i = 90433833342790,s = 0.0,p = 0 },{ n = "Femboy свитшот",i = 105804105689619,s = 0.0,p = 0 },{ n = "Femboy штаны",i = 72870106856318,s = 0.0,p = 0 },{ n = "redvetements",i = 75749441655962,s = 0.0,p = 777 },{ n = "Яндекс Доставка Футболка",i = 18662896578,s = 0.0,p = 0 },{ n = "пиджак чигура",i = 7798271981,s = 0.0,p = 100000 },{ n = "штаны чигура",i = 7798302571,s = 0.0,p = 100000 },}}]=],
}

local SHOP_CATALOG = { byName = {}, byId = {} }
local function syncShopCatalogFromAutobuy()
    for rarity, list in pairs(AUTOBUY_CATALOG_PARTS) do
        local ok, part = pcall(loadstring, "return " .. list)
        if ok and type(part) == "table" then
            for _, it in ipairs(part[rarity] or {}) do
                if it.n and it.i then
                    local id = tostring(it.i)
                    SHOP_CATALOG.byName[it.n] = { rarity = rarity, fairPrice = it.p, spawnChance = it.s, id = id }
                    SHOP_CATALOG.byId[id] = { name = it.n, rarity = rarity, fairPrice = it.p, spawnChance = it.s }
                end
            end
        end
    end
end
syncShopCatalogFromAutobuy()
print("[Catalog] TSUM loaded, items: " .. #SHOP_CATALOG.byId)

-- ============================================================
-- 3. ОСНОВНОЙ КОД (исправленный ESP + клики)
-- ============================================================
print("[OK] u1 loaded.")
local brandCount = 0
if u1 and u1.SHOP_ITEMS then for _ in pairs(u1.SHOP_ITEMS) do brandCount = brandCount + 1 end end
print("Brands in u1: " .. brandCount)
if brandCount == 0 then error("u1.SHOP_ITEMS is empty") end

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

print("AUTOBUY v24 + TSUM catalog (click detectors)")

local itemDataById = {}
local itemDataByTemplate = {}
local itemDataByName = {}

for brand, categories in pairs(u1.SHOP_ITEMS) do
    for category, items in pairs(categories) do
        for _, item in ipairs(items) do
            local id = tostring(item.id)
            local template = item.templateId and tostring(item.templateId) or nil
            local data = {
                name = item.name,
                price = item.fairPrice,
                rarity = item.rarity:lower(),
                type = item.type,
                brand = brand,
                spawnChance = item.spawnChance,
                economyProfile = item.economyProfile
            }
            if id and id ~= "" then itemDataById[id] = data end
            if template then itemDataByTemplate[template] = data end
            if not itemDataByName[item.name] then itemDataByName[item.name] = data end
        end
    end
end
local idCount = 0
for _ in pairs(itemDataById) do idCount = idCount + 1 end
print("[Data] u1 items by ID: " .. idCount)

local SETTINGS = {
    MAX_PER_SHOP = 15,
    MAX_TOTAL = 15,
    SUCCESS_DELAY = 2,
    FAIL_DELAY = 1,
    MOVE_INTERVAL = 2,
    WALK_SPEED = 18,
    JUMP_POWER = 50,
    PROMPT_ACTIVATE_DISTANCE = 5,
    MAX_RETRIES = 2,
    MAX_FAILED_ATTEMPTS = 2,
    MIN_PRICE = 0,
    MAX_PRICE = 999999,
    NAME_FILTER = "",
    SHOP_FILTER = "",
    RARITY_FILTER = "all",
    OBSTACLE_CHECK_DIST = 3.0,
    SIDE_STEP_DIST = 5,
    ESP_ENABLED = false,
    ESP_MAX_DIST = 250,
}

local RARITY_COLORS = {
    common = Color3.fromRGB(150,150,150),
    uncommon = Color3.fromRGB(50,200,50),
    rare = Color3.fromRGB(50,100,255),
    epic = Color3.fromRGB(180,50,255),
    legendary = Color3.fromRGB(255,200,50),
    exclusive = Color3.fromRGB(138,43,226),
    tokyoexclusive = Color3.fromRGB(255,100,200),
}
local RARITY_NAMES = {
    common = "Common",
    uncommon = "Uncommon",
    rare = "Rare",
    epic = "Epic",
    legendary = "Legendary",
    exclusive = "Exclusive",
    tokyoexclusive = "TokyoExclusive",
}

local function rarityByPrice(price)
    local tiers = {
        { min = 100000, rarity = "legendary" },
        { min = 50000,  rarity = "epic" },
        { min = 20000,  rarity = "rare" },
        { min = 5000,   rarity = "uncommon" },
        { min = 0,      rarity = "common" }
    }
    for _, tier in ipairs(tiers) do if price >= tier.min then return tier.rarity end end
    return "common"
end

local function log(msg) print("[AutoBuy] " .. msg) end
local function formatNumber(n)
    if n >= 1e6 then return string.format("%.1fM", n/1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
    else return tostring(n) end
end

local function findPosition(obj)
    local current = obj
    for _ = 1, 6 do
        if current:IsA("BasePart") then return current.Position end
        current = current.Parent
        if not current then break end
    end
    return nil
end

local function getItemIdFromModel(model)
    if not model then return nil end
    local attrs = model:GetAttributes()
    if attrs.id then return tostring(attrs.id) end
    if attrs.assetId then return tostring(attrs.assetId) end
    if attrs.templateId then return tostring(attrs.templateId) end
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") and child.Name:match("^%d+$") then
            return child.Name
        end
    end
    local name = model.Name
    local num = name:match("Att_(%d+)")
    if num then return num end
    num = name:match("^(%d+)$")
    if num then return num end
    return nil
end

local function getItemDataFromMap(model, itemName)
    local id = getItemIdFromModel(model)
    if id then
        local data = itemDataById[id]
        if data then return data end
        data = itemDataByTemplate[id]
        if data then return data end
        -- из каталога TSUM
        local cat = SHOP_CATALOG.byId[id]
        if cat then
            return { name = cat.name, price = cat.fairPrice, rarity = cat.rarity:lower(), brand = nil }
        end
    end
    -- поиск по имени в u1
    local data = itemDataByName[itemName]
    if data then return data end
    for name, d in pairs(itemDataByName) do
        if itemName:lower():find(name:lower()) or name:lower():find(itemName:lower()) then return d end
    end
    -- поиск по имени в TSUM
    local cat = SHOP_CATALOG.byName[itemName]
    if cat then
        return { name = cat.name, price = cat.fairPrice, rarity = cat.rarity:lower(), brand = nil }
    end
    for name, d in pairs(SHOP_CATALOG.byName) do
        if itemName:lower():find(name:lower()) or name:lower():find(itemName:lower()) then
            return { name = d.name, price = d.fairPrice, rarity = d.rarity:lower(), brand = nil }
        end
    end
    return nil
end

local priceCache = {}
local ShopRemotes = ReplicatedStorage:FindFirstChild("ShopRemotes")
local SlotPriceReveal = ShopRemotes and ShopRemotes:FindFirstChild("SlotPriceReveal")
if SlotPriceReveal then
    SlotPriceReveal.OnClientEvent:Connect(function(payload)
        if type(payload) == "table" then
            for _, item in ipairs(payload) do
                local ref = item.slotRef
                if typeof(ref) == "Instance" and ref:IsA("BasePart") then
                    local slotPath = ref:GetFullName()
                    priceCache[slotPath] = { name = tostring(item.name), price = tonumber(item.price) }
                end
            end
        end
    end)
end

local function buildRoute()
    local shops = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:match("^Shop_ShopZone_%d+$") then
            local pos = obj.PrimaryPart and obj.PrimaryPart.Position or nil
            if not pos then
                for _, part in ipairs(obj:GetChildren()) do
                    if part:IsA("BasePart") then pos = part.Position break end
                end
            end
            if pos then table.insert(shops, {name=obj.Name, position=pos}) end
        end
    end
    if #shops < 2 then return nil end
    local n = #shops
    local dist = {}
    for i = 1, n do
        dist[i] = {}
        for j = 1, n do
            if i == j then dist[i][j] = 0 else
                local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentMaxSlope = 45 })
                local s = pcall(function() path:ComputeAsync(shops[i].position, shops[j].position) end)
                if s and path.Status == Enum.PathStatus.Success then
                    local wps = path:GetWaypoints()
                    local d = 0
                    local prev = shops[i].position
                    for _, wp in ipairs(wps) do d = d + (wp.Position - prev).Magnitude; prev = wp.Position end
                    dist[i][j] = d
                else
                    dist[i][j] = (shops[j].position - shops[i].position).Magnitude
                end
            end
        end
    end
    local unvisited = {} for i = 1, n do unvisited[i] = true end
    local route = {}
    local startIdx = 1; local minStart = math.huge
    for i = 1, n do
        local d = (shops[i].position - rootPart.Position).Magnitude
        if d < minStart then minStart = d; startIdx = i end
    end
    table.insert(route, startIdx); unvisited[startIdx] = nil
    for _ = 2, n do
        local best, bestD = nil, math.huge
        for i in pairs(unvisited) do
            local d = dist[route[#route]][i]
            if d < bestD then bestD = d; best = i end
        end
        table.insert(route, best); unvisited[best] = nil
    end
    local final = {}
    for i, idx in ipairs(route) do final[i] = {name=shops[idx].name, position=shops[idx].position} end
    _G.bestRoute = final
    print("Route built: " .. #final .. " shops")
    return final
end
local route = _G.bestRoute or buildRoute()
if not route then error("No shops found") end

local function syncCartCount()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return end
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            for _, el in ipairs(gui:GetDescendants()) do
                if el.Name == "Count" and (el:IsA("TextLabel") or el:IsA("TextBox")) then
                    local current, max = el.Text:match("(%d+)%s*/%s*(%d+)")
                    if current then
                        takenCount = tonumber(current)
                        SETTINGS.MAX_TOTAL = tonumber(max) or 15
                    end
                    return
                end
            end
        end
    end
end

local function cartSyncUpdater()
    while running do
        syncCartCount()
        task.wait(0.5)
    end
end

local function walkTo(targetPos)
    if not targetPos or not humanoid or not rootPart then return false end
    local startPos = rootPart.Position
    local totalDistance = (targetPos - startPos).Magnitude
    if totalDistance <= 3 then return true end

    local originalWalkSpeed = humanoid.WalkSpeed
    local originalJumpPower = humanoid.JumpPower
    humanoid.WalkSpeed = SETTINGS.WALK_SPEED
    humanoid.JumpPower = SETTINGS.JUMP_POWER

    local lastPos = rootPart.Position
    local stuckTime = 0
    local startTime = tick()
    local maxTime = math.min(totalDistance * 0.8, 60)

    local avoidDir = nil
    local avoidTimer = 0
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {character}

    while tick() - startTime < maxTime do
        if not running then break end
        local pos = rootPart.Position
        if (pos - targetPos).Magnitude <= 3 then break end

        local moved = (pos - lastPos).Magnitude
        if moved < 0.3 then stuckTime = stuckTime + 0.15 else stuckTime = 0; avoidDir = nil; avoidTimer = 0 end
        lastPos = pos

        local dirToTarget = (targetPos - pos).Unit
        local low = pos + Vector3.new(0, 1.5, 0)
        local mid = pos + Vector3.new(0, 2.5, 0)
        local high = pos + Vector3.new(0, 3.5, 0)
        local rayLow = workspace:Raycast(low, dirToTarget * SETTINGS.OBSTACLE_CHECK_DIST, rayParams)
        local rayMid = workspace:Raycast(mid, dirToTarget * SETTINGS.OBSTACLE_CHECK_DIST, rayParams)
        local rayHigh = workspace:Raycast(high, dirToTarget * SETTINGS.OBSTACLE_CHECK_DIST, rayParams)

        local onlyHigh = rayHigh and not rayMid and not rayLow
        local bodyBlocked = rayMid or rayLow

        if not bodyBlocked and not onlyHigh then
            humanoid:MoveTo(targetPos)
        elseif onlyHigh then
            humanoid:MoveTo(targetPos)
        else
            if stuckTime >= 1 then
                if not avoidDir then
                    local right = dirToTarget:Cross(Vector3.new(0,1,0)).Unit
                    local left = -right
                    local function clear(dir)
                        return workspace:Raycast(low, dir * SETTINGS.SIDE_STEP_DIST, rayParams) == nil
                            and workspace:Raycast(mid, dir * SETTINGS.SIDE_STEP_DIST, rayParams) == nil
                            and workspace:Raycast(high, dir * SETTINGS.SIDE_STEP_DIST, rayParams) == nil
                    end
                    local rClear, lClear = clear(right), clear(left)
                    if rClear and lClear then
                        local dotR = right:Dot(dirToTarget)
                        local dotL = left:Dot(dirToTarget)
                        avoidDir = dotR > dotL and right or left
                    elseif rClear then avoidDir = right
                    elseif lClear then avoidDir = left
                    else
                        humanoid:MoveTo(pos - dirToTarget * 3)
                        task.wait(0.5)
                        avoidDir = right
                    end
                    avoidTimer = tick()
                end
                local moveDir = (avoidDir + dirToTarget * 0.4).Unit
                humanoid:MoveTo(pos + moveDir * SETTINGS.SIDE_STEP_DIST)
                if tick() - avoidTimer > 1.5 then avoidDir = nil end
            else
                humanoid:MoveTo(targetPos)
            end
        end
        if stuckTime >= 2 and moved < 0.1 then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            stuckTime = 0
        end
        task.wait(0.1)
    end
    humanoid.WalkSpeed = originalWalkSpeed
    humanoid.JumpPower = originalJumpPower
    if (rootPart.Position - targetPos).Magnitude > 3 then humanoid:MoveTo(targetPos); task.wait(0.5) end
    return (rootPart.Position - targetPos).Magnitude <= 3
end

local clothes = {}
local seller = nil
local running = false
local takenCount = 0
local paidCount = 0
local shopLimits = {}
local lastMoveTime = 0
local totalItemsBought = 0
local totalMoneySpent = 0
local cycleCount = 0

local function shouldBuyItem(item)
    if not item.price then return false end
    if item.price < SETTINGS.MIN_PRICE or item.price > SETTINGS.MAX_PRICE then return false end
    if SETTINGS.NAME_FILTER ~= "" and not item.name:lower():find(SETTINGS.NAME_FILTER:lower()) then return false end
    if SETTINGS.SHOP_FILTER ~= "" then
        local filter = SETTINGS.SHOP_FILTER:lower()
        local match = false
        if item.shop:lower():find(filter) then match = true end
        if not match and item.brand and item.brand:lower():find(filter) then match = true end
        if not match then return false end
    end
    if SETTINGS.RARITY_FILTER ~= "all" and item.rarity ~= SETTINGS.RARITY_FILTER then return false end
    return true
end

local function findSeller()
    if seller then return seller end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") then
            local parent = obj.Parent
            if parent then
                local name = parent.Name:lower()
                if name:find("кассир") or name:find("cashier") or name:find("оплат") or name:find("pay") then
                    seller = { obj = obj, position = findPosition(obj) }
                    log("Seller found: " .. parent.Name)
                    return seller
                end
            end
        end
    end
    return nil
end

-- ===== НОВАЯ findClothes (ClickDetector) =====
local function findClothes()
    clothes = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") then
            local parent = obj.Parent
            if not parent then continue end
            local rawName = parent.Name or "Item"
            local position = findPosition(parent)
            local path = obj:GetFullName()
            local shopName = "Unknown"
            for name in path:gmatch("Shop_ShopZone_%d+") do shopName = name; break end
            if shopName == "Unknown" then
                for name in path:gmatch("Shop_[%w_]+") do shopName = name; break end
            end
            local floor = "1st floor"
            if position and position.Y > 10 then floor = "2nd floor" end

            local data = getItemDataFromMap(parent, rawName)
            local price = data and data.price or nil
            local rarity = data and data.rarity or nil
            local displayName = data and data.name or rawName
            local brand = data and data.brand or nil

            if not price then
                local slotPath = parent:GetFullName()
                local cached = priceCache[slotPath]
                if cached then
                    price = cached.price
                    displayName = cached.name or rawName
                    rarity = rarity or (price and rarityByPrice(price))
                end
            end

            table.insert(clothes, {
                obj = obj,          -- ClickDetector
                parent = parent,
                name = displayName,
                position = position,
                shop = shopName,
                brand = brand,
                floor = floor,
                taken = false,
                unavailable = false,
                failedAttempts = 0,
                rarity = rarity,
                price = price,
                slotRef = parent,
                rawName = rawName
            })
        end
    end
    local withPrice = 0
    for _, it in ipairs(clothes) do if it.price then withPrice = withPrice + 1 end end
    log("Found " .. #clothes .. " items, with price: " .. withPrice)
end

-- ===== НОВАЯ activatePrompt (клик по ClickDetector) =====
local function activatePrompt(clickDetector)
    if not clickDetector then return false end
    local pos = findPosition(clickDetector.Parent)
    if pos and (pos - rootPart.Position).Magnitude > SETTINGS.PROMPT_ACTIVATE_DISTANCE then
        walkTo(pos)
        task.wait(0.5)
    end
    if fireclickdetector then
        if pcall(function() fireclickdetector(clickDetector) end) then return true end
    end
    if clickDetector:IsA("ClickDetector") then
        return pcall(function() clickDetector:FireClick() end)
    end
    return false
end

local function tryTakeItem(item)
    if item.unavailable then return false end
    if not item.obj or not item.obj.Parent then item.unavailable = true; return false end
    for attempt = 1, SETTINGS.MAX_RETRIES do
        if not running then return false end
        if attempt > 1 then
            task.wait(SETTINGS.FAIL_DELAY)
            if not item.obj or not item.obj.Parent then item.unavailable = true; return false end
        end
        if activatePrompt(item.obj) then
            return true
        end
    end
    item.failedAttempts = item.failedAttempts + 1
    if item.failedAttempts >= SETTINGS.MAX_FAILED_ATTEMPTS then item.unavailable = true end
    return false
end

local function pay()
    local confirm = ReplicatedStorage:FindFirstChild("ShopRemotes", true)
    if confirm then confirm = confirm:FindFirstChild("ConfirmPurchase") end
    if confirm and pcall(function() confirm:FireServer() end) then return true end
    if player:FindFirstChild("PlayerGui") then
        local gui = player.PlayerGui:FindFirstChild("ShopGUI")
        if gui then
            local btn = gui:FindFirstChild("BuyButton", true)
            if btn and btn:IsA("TextButton") then
                local pos = btn.AbsolutePosition
                local sz = btn.AbsoluteSize
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(pos.X + sz.X/2, pos.Y + sz.Y/2))
                return true
            end
        end
    end
    return false
end

local function goToPay()
    if takenCount == 0 then return end
    findSeller()
    if not seller then log("No seller") return end
    if seller.position then walkTo(seller.position) task.wait(1) end
    activatePrompt(seller.obj)   -- клик по кассиру
    task.wait(2)
    local paid = pay()
    if paid then
        paidCount = paidCount + 1
        totalItemsBought = totalItemsBought + takenCount
        cycleCount = cycleCount + 1
        takenCount = 0
    else
        task.wait(1)
        paid = pay()
        if paid then
            paidCount = paidCount + 1
            totalItemsBought = totalItemsBought + takenCount
            cycleCount = cycleCount + 1
            takenCount = 0
        else
            log("Payment failed")
        end
    end
end

local function doQuickMove()
    local now = tick()
    if now - lastMoveTime >= SETTINGS.MOVE_INTERVAL then
        if humanoid and humanoid.Health > 0 then
            humanoid:MoveTo(rootPart.Position + Vector3.new(math.random(-2,2),0,math.random(-2,2)))
            lastMoveTime = now
        end
    end
end

local function updateRestockDisplay()
    local text = "Restock: "
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, el in ipairs(gui:GetDescendants()) do
                    if el.Name == "TimerLabel" then
                        text = el.Text
                        break
                    end
                end
            end
        end
    end
    if text == "Restock: " then text = "Restock: --:--" end
    return text
end

local function waitForRestock()
    while running do
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            for _, gui in ipairs(playerGui:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    for _, el in ipairs(gui:GetDescendants()) do
                        if el.Name == "TimerLabel" then
                            local min, sec = el.Text:match("(%d+):(%d+)")
                            if min and sec then
                                local remaining = tonumber(min)*60 + tonumber(sec)
                                if remaining >= 590 then
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
        doQuickMove()
        task.wait(1)
    end
end

-- ========== Main Loop ==========
local function mainLoop()
    task.spawn(cartSyncUpdater)
    while running do
        for _, item in ipairs(clothes) do
            item.taken = false
            item.unavailable = false
            item.failedAttempts = 0
        end
        shopLimits = {}
        takenCount = 0
        lastMoveTime = tick()
        findClothes()
        updateList()
        log("New cycle.")

        local paid = false
        for shopIdx, shop in ipairs(route) do
            if not running or paid then break end
            syncCartCount()
            if takenCount >= SETTINGS.MAX_TOTAL then
                goToPay()
                paid = true
                break
            end

            log("=== Entering " .. shop.name .. " ===")
            walkTo(shop.position)
            task.wait(1)

            local shopItems = {}
            for _, item in ipairs(clothes) do
                if item.shop == shop.name and not item.taken and not item.unavailable and shouldBuyItem(item) then
                    table.insert(shopItems, item)
                end
            end

            local curPos = rootPart.Position
            table.sort(shopItems, function(a, b)
                local dA = a.position and (a.position - curPos).Magnitude or 9999
                local dB = b.position and (b.position - curPos).Magnitude or 9999
                return dA < dB
            end)

            for _, item in ipairs(shopItems) do
                if not running then break end
                syncCartCount()
                if takenCount >= SETTINGS.MAX_TOTAL then break end
                if item.taken or item.unavailable then continue end

                if item.position then
                    walkTo(item.position)
                    task.wait(0.3)
                end

                local success = tryTakeItem(item)
                if success then
                    item.taken = true
                    totalMoneySpent = totalMoneySpent + (item.price or 0)
                    syncCartCount()
                    updateStats()
                    updateList()
                    local waitStart = tick()
                    while tick() - waitStart < SETTINGS.SUCCESS_DELAY do
                        if not running then break end
                        doQuickMove()
                        task.wait(0.5)
                    end
                else
                    item.unavailable = true
                    updateList()
                    local waitStart = tick()
                    while tick() - waitStart < SETTINGS.FAIL_DELAY do
                        if not running then break end
                        doQuickMove()
                        task.wait(0.5)
                    end
                end
            end

            if takenCount > 0 then
                goToPay()
                paid = true
                break
            end

            if shopIdx == #route then break end
        end

        if not paid and takenCount > 0 then
            goToPay()
        end

        if running then
            findClothes()
            updateList()
            waitForRestock()
        end
    end
end

-- ========== ESP ==========
local espGui, espPool, espLive, espConn

local function ensureEspScreen()
    if espGui and espGui.Parent then return end
    espGui = Instance.new("ScreenGui")
    espGui.Name = "AutoBuy_ESP"
    espGui.ResetOnSpawn = false
    espGui.DisplayOrder = 500
    espGui.Parent = player:WaitForChild("PlayerGui")
    espPool = {}
    espLive = {}
end

local function acquireEspWidget()
    local w = table.remove(espPool)
    if w then return w end
    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromOffset(0, 0)
    holder.Visible = false
    holder.Parent = espGui

    local tracer = Instance.new("Frame")
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.ZIndex = 2
    tracer.Parent = holder

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.ZIndex = 3
    box.Parent = holder
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Parent = box

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromOffset(300, 36)
    label.TextWrapped = true
    label.AnchorPoint = Vector2.new(0.5, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextStrokeTransparency = 0.3
    label.ZIndex = 4
    label.Parent = holder

    return { holder = holder, tracer = tracer, box = box, stroke = stroke, label = label }
end

local function releaseEspWidget(w)
    w.holder.Visible = false
    table.insert(espPool, w)
end

local function drawLine(frame, fromPos, toPos, thickness, color)
    local dx = toPos.X - fromPos.X
    local dy = toPos.Y - fromPos.Y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist < 2 then
        frame.Visible = false
        return
    end
    frame.Visible = true
    frame.BackgroundColor3 = color
    frame.Size = UDim2.fromOffset(dist, thickness)
    frame.Position = UDim2.fromOffset((fromPos.X + toPos.X) / 2, (fromPos.Y + toPos.Y) / 2)
    frame.Rotation = math.deg(math.atan2(dy, dx))
end

local function renderESP()
    if not SETTINGS.ESP_ENABLED then
        for holder, w in pairs(espLive) do
            releaseEspWidget(w)
        end
        espLive = {}
        return
    end
    ensureEspScreen()
    local camera = workspace.CurrentCamera
    local hrp = rootPart
    if not camera or not hrp then return end

    local active = {}
    local tracerFrom = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y - 6)
    local items = getBuyableItems()

    for _, item in ipairs(items) do
        if not item.position then continue end
        local worldPos = item.position + Vector3.new(0, 2.2, 0)
        if (worldPos - hrp.Position).Magnitude > SETTINGS.ESP_MAX_DIST then continue end
        local screenPos, onScreen = camera:WorldToViewportPoint(worldPos)
        if not onScreen or screenPos.Z <= 0 then continue end
        local color = RARITY_COLORS[item.rarity] or Color3.fromRGB(200,200,200)
        local w = acquireEspWidget()
        espLive[w.holder] = w
        active[w.holder] = true
        local center = Vector2.new(screenPos.X, screenPos.Y)
        local boxSize = math.clamp(3200 / math.max(screenPos.Z, 1), 24, 140)
        drawLine(w.tracer, tracerFrom, center, 2, color)
        w.box.Visible = true
        w.box.Size = UDim2.fromOffset(boxSize, boxSize)
        w.box.Position = UDim2.fromOffset(center.X - boxSize/2, center.Y - boxSize/2)
        w.stroke.Color = color
        local labelText = string.format("[%s] %s $%s", (RARITY_NAMES[item.rarity] or "?"), item.name, item.price or "?")
        if #labelText > 40 then labelText = labelText:sub(1,38)..".." end
        w.label.Text = labelText
        w.label.TextColor3 = color
        w.label.Position = UDim2.fromOffset(center.X, center.Y - boxSize/2 - 4)
        w.label.Visible = true
        w.holder.Visible = true
    end

    for holder in pairs(espLive) do
        if not active[holder] then
            releaseEspWidget(espLive[holder])
            espLive[holder] = nil
        end
    end
end

local function toggleESP(on)
    SETTINGS.ESP_ENABLED = on
    if on then
        if not espConn then
            espConn = RunService.RenderStepped:Connect(renderESP)
        end
        print("[ESP] ON")
    else
        if espConn then
            espConn:Disconnect()
            espConn = nil
        end
        if espGui then espGui:Destroy(); espGui = nil end
        espPool = {}
        espLive = {}
        print("[ESP] OFF")
    end
end

local function updateESP() end

-- ========== GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoBuy_v24_ESP"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 750, 0, 880)
frame.Position = UDim2.new(0, 100, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(10,10,10)
frame.BorderSizePixel = 0
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,55)
titleBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,10)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1,-45,1,0)
titleLabel.Position = UDim2.new(0,10,0,0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = " AutoBuy v24 + ESP (TSUM catalog)"
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,40,0,40)
closeBtn.Position = UDim2.new(1,-45,0,7)
closeBtn.BackgroundColor3 = Color3.fromRGB(220,50,50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,8)
closeBtn.MouseButton1Click:Connect(function()
    running = false
    screenGui:Destroy()
    toggleESP(false)
end)

local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
local function updateDrag(input)
    if dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UIS.InputChanged:Connect(function(input)
    if input == dragInput then updateDrag(input) end
end)

local restockLabel = Instance.new("TextLabel")
restockLabel.Size = UDim2.new(1,-20,0,30)
restockLabel.Position = UDim2.new(0,10,0,55)
restockLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
restockLabel.TextColor3 = Color3.fromRGB(255,255,100)
restockLabel.Font = Enum.Font.GothamBold
restockLabel.TextSize = 16
restockLabel.Text = "Restock: --:--"
restockLabel.TextXAlignment = Enum.TextXAlignment.Center
restockLabel.Parent = frame
Instance.new("UICorner", restockLabel).CornerRadius = UDim.new(0,8)

local filterFrame = Instance.new("Frame")
filterFrame.Size = UDim2.new(1,-20,0,150)
filterFrame.Position = UDim2.new(0,10,0,90)
filterFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
filterFrame.Parent = frame
Instance.new("UICorner", filterFrame).CornerRadius = UDim.new(0,8)

local filterTitle = Instance.new("TextLabel")
filterTitle.Size = UDim2.new(1,-10,0,20)
filterTitle.Position = UDim2.new(0,5,0,0)
filterTitle.BackgroundTransparency = 1
filterTitle.Text = " Price filter (Min / Max)"
filterTitle.TextColor3 = Color3.new(1,1,1)
filterTitle.Font = Enum.Font.GothamBold
filterTitle.TextSize = 11
filterTitle.TextXAlignment = Enum.TextXAlignment.Left
filterTitle.Parent = filterFrame

local priceMinLabel = Instance.new("TextLabel")
priceMinLabel.Size = UDim2.new(0.15,0,0,25)
priceMinLabel.Position = UDim2.new(0,5,0,25)
priceMinLabel.BackgroundTransparency = 1
priceMinLabel.Text = "Min $"
priceMinLabel.TextColor3 = Color3.new(1,1,1)
priceMinLabel.Font = Enum.Font.GothamBold
priceMinLabel.TextSize = 11
priceMinLabel.TextXAlignment = Enum.TextXAlignment.Left
priceMinLabel.Parent = filterFrame

local priceMinInput = Instance.new("TextBox")
priceMinInput.Size = UDim2.new(0.15,0,0,25)
priceMinInput.Position = UDim2.new(0.15,5,0,25)
priceMinInput.BackgroundColor3 = Color3.fromRGB(40,40,40)
priceMinInput.TextColor3 = Color3.new(1,1,1)
priceMinInput.Text = tostring(SETTINGS.MIN_PRICE)
priceMinInput.Font = Enum.Font.Gotham
priceMinInput.TextSize = 11
priceMinInput.Parent = filterFrame
Instance.new("UICorner", priceMinInput).CornerRadius = UDim.new(0,4)
priceMinInput.FocusLost:Connect(function()
    local val = tonumber(priceMinInput.Text)
    if val then
        SETTINGS.MIN_PRICE = val
        updateList()
        updateESP()
    end
end)

local priceMaxLabel = Instance.new("TextLabel")
priceMaxLabel.Size = UDim2.new(0.15,0,0,25)
priceMaxLabel.Position = UDim2.new(0.35,5,0,25)
priceMaxLabel.BackgroundTransparency = 1
priceMaxLabel.Text = "Max $"
priceMaxLabel.TextColor3 = Color3.new(1,1,1)
priceMaxLabel.Font = Enum.Font.GothamBold
priceMaxLabel.TextSize = 11
priceMaxLabel.TextXAlignment = Enum.TextXAlignment.Left
priceMaxLabel.Parent = filterFrame

local priceMaxInput = Instance.new("TextBox")
priceMaxInput.Size = UDim2.new(0.15,0,0,25)
priceMaxInput.Position = UDim2.new(0.5,5,0,25)
priceMaxInput.BackgroundColor3 = Color3.fromRGB(40,40,40)
priceMaxInput.TextColor3 = Color3.new(1,1,1)
priceMaxInput.Text = tostring(SETTINGS.MAX_PRICE)
priceMaxInput.Font = Enum.Font.Gotham
priceMaxInput.TextSize = 11
priceMaxInput.Parent = filterFrame
Instance.new("UICorner", priceMaxInput).CornerRadius = UDim.new(0,4)
priceMaxInput.FocusLost:Connect(function()
    local val = tonumber(priceMaxInput.Text)
    if val then
        SETTINGS.MAX_PRICE = val
        updateList()
        updateESP()
    end
end)

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(0.2,0,0,25)
nameLabel.Position = UDim2.new(0,5,0,55)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Name:"
nameLabel.TextColor3 = Color3.new(1,1,1)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 11
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = filterFrame

local nameInput = Instance.new("TextBox")
nameInput.Size = UDim2.new(0.3,0,0,25)
nameInput.Position = UDim2.new(0.2,5,0,55)
nameInput.BackgroundColor3 = Color3.fromRGB(40,40,40)
nameInput.TextColor3 = Color3.new(1,1,1)
nameInput.Text = SETTINGS.NAME_FILTER
nameInput.PlaceholderText = "all"
nameInput.Font = Enum.Font.Gotham
nameInput.TextSize = 11
nameInput.Parent = filterFrame
Instance.new("UICorner", nameInput).CornerRadius = UDim.new(0,4)
nameInput.FocusLost:Connect(function()
    SETTINGS.NAME_FILTER = nameInput.Text
    updateList()
    updateESP()
end)

local shopLabel = Instance.new("TextLabel")
shopLabel.Size = UDim2.new(0.2,0,0,25)
shopLabel.Position = UDim2.new(0.5,5,0,55)
shopLabel.BackgroundTransparency = 1
shopLabel.Text = "Shop:"
shopLabel.TextColor3 = Color3.new(1,1,1)
shopLabel.Font = Enum.Font.GothamBold
shopLabel.TextSize = 11
shopLabel.TextXAlignment = Enum.TextXAlignment.Left
shopLabel.Parent = filterFrame

local shopInput = Instance.new("TextBox")
shopInput.Size = UDim2.new(0.3,0,0,25)
shopInput.Position = UDim2.new(0.7,5,0,55)
shopInput.BackgroundColor3 = Color3.fromRGB(40,40,40)
shopInput.TextColor3 = Color3.new(1,1,1)
shopInput.Text = SETTINGS.SHOP_FILTER
shopInput.PlaceholderText = "all"
shopInput.Font = Enum.Font.Gotham
shopInput.TextSize = 11
shopInput.Parent = filterFrame
Instance.new("UICorner", shopInput).CornerRadius = UDim.new(0,4)
shopInput.FocusLost:Connect(function()
    SETTINGS.SHOP_FILTER = shopInput.Text
    updateList()
    updateESP()
end)

local rarityLabel = Instance.new("TextLabel")
rarityLabel.Size = UDim2.new(0.15,0,0,20)
rarityLabel.Position = UDim2.new(0,5,0,85)
rarityLabel.BackgroundTransparency = 1
rarityLabel.Text = "Rarity:"
rarityLabel.TextColor3 = Color3.new(1,1,1)
rarityLabel.Font = Enum.Font.GothamBold
rarityLabel.TextSize = 11
rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
rarityLabel.Parent = filterFrame

local rarityBtnFrame = Instance.new("Frame")
rarityBtnFrame.Size = UDim2.new(0.8, -10, 0, 32)
rarityBtnFrame.Position = UDim2.new(0.15, 5, 0, 80)
rarityBtnFrame.BackgroundTransparency = 1
rarityBtnFrame.Parent = filterFrame

local rarityList = {"all", "common", "uncommon", "rare", "epic", "legendary"}
local rarityButtons = {}
local activeRarityBtn = nil

local function updateRarityButtons(selected)
    for i, btn in ipairs(rarityButtons) do
        local isActive = (btn == selected)
        if isActive then
            btn.BackgroundColor3 = Color3.fromRGB(255,255,255)
            btn.TextColor3 = Color3.new(0,0,0)
            btn.BorderSizePixel = 2
            btn.BorderColor3 = Color3.fromRGB(255,200,50)
        else
            btn.BackgroundColor3 = (rarityList[i] == "all") and Color3.fromRGB(80,80,80) or RARITY_COLORS[rarityList[i]]
            btn.TextColor3 = Color3.new(1,1,1)
            btn.BorderSizePixel = 0
        end
    end
end

for i, r in ipairs(rarityList) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/#rarityList, -2, 1, -2)
    btn.Position = UDim2.new((i-1)/#rarityList, 1, 0, 1)
    btn.BackgroundColor3 = (r == "all") and Color3.fromRGB(80,80,80) or RARITY_COLORS[r]
    local displayName = (r == "all") and "All" or string.upper(r:sub(1,1)) .. r:sub(2)
    btn.Text = displayName
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Parent = rarityBtnFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
    btn.MouseButton1Click:Connect(function()
        SETTINGS.RARITY_FILTER = r
        activeRarityBtn = btn
        updateRarityButtons(btn)
        updateList()
        updateESP()
    end)
    table.insert(rarityButtons, btn)
end
activeRarityBtn = rarityButtons[1]
updateRarityButtons(activeRarityBtn)

local espToggle = Instance.new("TextButton")
espToggle.Size = UDim2.new(0.5, -10, 0, 32)
espToggle.Position = UDim2.new(0, 5, 0, 120)
espToggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
espToggle.Text = "ESP: OFF"
espToggle.TextColor3 = Color3.new(1,1,1)
espToggle.Font = Enum.Font.GothamBold
espToggle.TextSize = 12
espToggle.Parent = filterFrame
Instance.new("UICorner", espToggle).CornerRadius = UDim.new(0,6)
espToggle.MouseButton1Click:Connect(function()
    local newVal = not SETTINGS.ESP_ENABLED
    toggleESP(newVal)
    espToggle.Text = newVal and "ESP: ON" or "ESP: OFF"
    espToggle.BackgroundColor3 = newVal and Color3.fromRGB(80,200,80) or Color3.fromRGB(40,40,40)
end)

local filterStats = Instance.new("TextLabel")
filterStats.Size = UDim2.new(1,-10,0,20)
filterStats.Position = UDim2.new(0,10,0,245)
filterStats.BackgroundTransparency = 1
filterStats.Text = "Total: 0 | Filtered: 0"
filterStats.TextColor3 = Color3.fromRGB(200,200,200)
filterStats.Font = Enum.Font.Gotham
filterStats.TextSize = 10
filterStats.TextXAlignment = Enum.TextXAlignment.Left
filterStats.Parent = frame

local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1,-20,0,80)
statsFrame.Position = UDim2.new(0,10,0,270)
statsFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
statsFrame.Parent = frame
Instance.new("UICorner", statsFrame).CornerRadius = UDim.new(0,8)

local takenLabel = Instance.new("TextLabel")
takenLabel.Size = UDim2.new(0.33,-5,0.5,0)
takenLabel.Position = UDim2.new(0,5,0,0)
takenLabel.BackgroundTransparency = 1
takenLabel.Text = " Taken: 0/" .. SETTINGS.MAX_TOTAL
takenLabel.TextColor3 = Color3.fromRGB(255,200,100)
takenLabel.Font = Enum.Font.GothamBold
takenLabel.TextSize = 12
takenLabel.TextXAlignment = Enum.TextXAlignment.Left
takenLabel.Parent = statsFrame

local paidLabel = Instance.new("TextLabel")
paidLabel.Size = UDim2.new(0.33,-5,0.5,0)
paidLabel.Position = UDim2.new(0.33,5,0,0)
paidLabel.BackgroundTransparency = 1
paidLabel.Text = " Paid: 0"
paidLabel.TextColor3 = Color3.fromRGB(100,200,255)
paidLabel.Font = Enum.Font.GothamBold
paidLabel.TextSize = 12
paidLabel.TextXAlignment = Enum.TextXAlignment.Left
paidLabel.Parent = statsFrame

local totalLabel = Instance.new("TextLabel")
totalLabel.Size = UDim2.new(0.33,-5,0.5,0)
totalLabel.Position = UDim2.new(0.66,5,0,0)
totalLabel.BackgroundTransparency = 1
totalLabel.Text = " Cycles: 0"
totalLabel.TextColor3 = Color3.fromRGB(200,200,200)
totalLabel.Font = Enum.Font.GothamBold
totalLabel.TextSize = 12
totalLabel.TextXAlignment = Enum.TextXAlignment.Left
totalLabel.Parent = statsFrame

local itemsLabel = Instance.new("TextLabel")
itemsLabel.Size = UDim2.new(0.5,-5,0.5,0)
itemsLabel.Position = UDim2.new(0,5,0.5,0)
itemsLabel.BackgroundTransparency = 1
itemsLabel.Text = " Bought: 0"
itemsLabel.TextColor3 = Color3.fromRGB(180,180,180)
itemsLabel.Font = Enum.Font.Gotham
itemsLabel.TextSize = 11
itemsLabel.TextXAlignment = Enum.TextXAlignment.Left
itemsLabel.Parent = statsFrame

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(0.5,-5,0.5,0)
moneyLabel.Position = UDim2.new(0.5,5,0.5,0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = " Spent: $0"
moneyLabel.TextColor3 = Color3.fromRGB(180,180,180)
moneyLabel.Font = Enum.Font.Gotham
moneyLabel.TextSize = 11
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = statsFrame

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1,-20,0,55)
startBtn.Position = UDim2.new(0,10,0,360)
startBtn.BackgroundColor3 = Color3.fromRGB(80,200,80)
startBtn.Text = "START"
startBtn.TextColor3 = Color3.new(0,0,0)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 16
startBtn.Parent = frame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0,10)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1,-20,0,30)
statusLabel.Position = UDim2.new(0,10,0,420)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Ready"
statusLabel.TextColor3 = Color3.fromRGB(100,255,100)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1,-20,0,100)
logLabel.Position = UDim2.new(0,10,0,455)
logLabel.BackgroundTransparency = 1
logLabel.Text = " Log:"
logLabel.TextColor3 = Color3.fromRGB(180,180,180)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 11
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.Parent = frame

local logText = {}
local function addLog(msg)
    table.insert(logText, msg)
    if #logText > 7 then table.remove(logText, 1) end
    logLabel.Text = "Log:\n" .. table.concat(logText, "\n")
end

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1,-20,1,-560)
scrollFrame.Position = UDim2.new(0,10,0,560)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = frame
Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0,8)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0,4)
listLayout.Parent = scrollFrame

local function updateStats()
    takenLabel.Text = "Taken: " .. takenCount .. "/" .. SETTINGS.MAX_TOTAL
    paidLabel.Text = "Paid: " .. paidCount
    totalLabel.Text = "Cycles: " .. cycleCount
    itemsLabel.Text = "Bought: " .. totalItemsBought
    moneyLabel.Text = "Spent: $" .. formatNumber(totalMoneySpent)
end

local function getFilteredItems()
    local filtered = {}
    for _, item in ipairs(clothes) do
        if not item.taken and not item.unavailable and shouldBuyItem(item) then
            table.insert(filtered, item)
        end
    end
    return filtered
end

local function updateList()
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local filtered = getFilteredItems()
    filterStats.Text = "Total: " .. #clothes .. " | Filtered: " .. #filtered
    for i, item in ipairs(filtered) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1,-10,0,65)
        itemFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
        itemFrame.LayoutOrder = i
        itemFrame.Parent = scrollFrame
        Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0,8)

        local rarityBar = Instance.new("Frame")
        rarityBar.Size = UDim2.new(0,4,1,0)
        rarityBar.BackgroundColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(150,150,150)
        rarityBar.Parent = itemFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1,-15,0,20)
        nameLabel.Position = UDim2.new(0,10,0,3)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = item.name or "??"
        nameLabel.TextColor3 = Color3.new(1,1,1)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = itemFrame

        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1,-15,0,18)
        infoLabel.Position = UDim2.new(0,10,0,23)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Text = (item.brand or item.shop) .. " | " .. item.floor .. " | $" .. (item.price or "?")
        infoLabel.TextColor3 = Color3.fromRGB(180,180,180)
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextSize = 10
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = itemFrame

        local rarityLabel = Instance.new("TextLabel")
        rarityLabel.Size = UDim2.new(1,-15,0,18)
        rarityLabel.Position = UDim2.new(0,10,0,41)
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.Text = RARITY_NAMES[item.rarity] or "?"
        rarityLabel.TextColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(150,150,150)
        rarityLabel.Font = Enum.Font.GothamBold
        rarityLabel.TextSize = 10
        rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
        rarityLabel.Parent = itemFrame
    end
    scrollFrame.CanvasSize = UDim2.new(0,0,0, listLayout.AbsoluteContentSize.Y + 10)
end

-- ========== Start ==========
startBtn.MouseButton1Click:Connect(function()
    if running then
        running = false
        startBtn.Text = "START"
        startBtn.BackgroundColor3 = Color3.fromRGB(80,200,80)
        toggleESP(false)
        espToggle.Text = "ESP: OFF"
        espToggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
    else
        running = true
        startBtn.Text = "STOP"
        startBtn.BackgroundColor3 = Color3.fromRGB(220,50,50)
        findClothes()
        updateStats()
        updateList()
        if SETTINGS.ESP_ENABLED then
            toggleESP(true)
            espToggle.Text = "ESP: ON"
            espToggle.BackgroundColor3 = Color3.fromRGB(80,200,80)
        end
        task.spawn(function()
            while running do
                restockLabel.Text = updateRestockDisplay()
                task.wait(1)
            end
        end)
        task.spawn(mainLoop)
    end
end)

findClothes()
updateStats()
updateList()
restockLabel.Text = updateRestockDisplay()
task.delay(2, function()
    toggleESP(true)
    espToggle.Text = "ESP: ON"
    espToggle.BackgroundColor3 = Color3.fromRGB(80,200,80)
end)
print("AutoBuy v24 + ESP (TSUM catalog, click detectors) loaded.")
