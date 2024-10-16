Config = {}

Config.AutomaattiPropit = {
    'prop_atm_01',
    'prop_atm_02',
    'prop_atm_03'
}

Config.AutomaattiCooldown = 21600

Config.Palkkiot = {
    {item = 'money', itemlabel = 'Käteinen', maxMaara = 2000, minMaara = 500, chance = 100}, 
    {item = 'black_money', itemlabel = 'Likainen raha', maxMaara = 22000, minMaara = 2500, chance = 50}  
}


Config.IskuMahdollisuus = 30
Config.IskunKesto = 30
Config.RyostaTapa = 'textui' -- 'target', 'textui'
Config.PoliisinIlmoitus = 'cd' -- 'cd', 'normi'
Config.PoliisinBlipKesto = 60 -- vain normi ilmotukseen
