const nickNameGenerator = async () => {
    const first_name = [
      "The", "A", "An", "Captain", "Dr", "Sir", "Lady", "Master", "El", "La", "Major", 
      "Agent", "Commander", "Professor", "Knight", "Warden", "Guardian", "Hawkwing", 
      "Shadowborn", "Phantom", "Mystic", "Crimson", "Iron", "Steel", "Golden", "Silver",
      "Ancient", "Ethereal", "Luminous", "Infernal", "Frozen", "Vanguard", "Silent",
      "True", "Bold", "Eternal", "Infinite", "Radiant", "Arcane", "Solar", "Lunar",
      "Venomous", "Stealthy", "Sacred", "Cursed", "Fierce", "Brave", "Swift", "Noble", 
      "Dark", "Glorious", "Hidden", "Rising", "Burning", "Wild", "Celestial", "Vicious",
      "Frozenflame", "Dreaded", "Savage", "Primal", "Thunderous", "Ominous", "Blazing",
      "Dreadnought", "Howling", "Silentshade", "Glinting", "Blistering", "Aetherial",
      "Shimmering", "Starborn", "Voidwalker", "Ashen", "Gilded", "Everlasting", "Gleaming",
      "Whispering", "Runic", "Shrouded", "Blighted", "Stormbreaker", "Voidshard", "Brimstone",
      "Heavenly", "Frosted", "Solarflare", "Shadowveil", "Tempestuous", "Galactic"
    ];
  
    const middle_name = [
      "Lone", "Nova", "Cinder", "Rogue", "Blaze", "Frost", "Comet", "Ash", "Bolt", "Sting", 
      "Flare", "Talon", "Specter", "Shade", "Phantom", "Saber", "Axel", "Rune", "Quill", 
      "Nimbus", "Drifter", "Hunter", "Seeker", "Blight", "Echo", "Aurora", "Glare", "Ember", 
      "Spark", "Falcon", "Viper", "Sable", "Zephyr", "Shard", "Inferno", "Phoenix", "Wraith",
      "Fang", "Thorn", "Pulse", "Stellar", "Venom", "Quasar", "Lancer", "Comet", "Rider", 
      "Dagger", "Prism", "Frostbite", "Blitz", "Vortex", "Berserker", "Loom", "Halcyon", 
      "Orion", "Ravager", "Ashen", "Cypher", "Eclipse", "Helix", "Pyro", "Ardent", "Halberd", 
      "Tempest", "Howl", "Glitch", "Loom", "Void", "Drake", "Cipher", "Spectral", "Onyx",
      "Astro", "Flint", "Grit", "Pike", "Ignis", "Arc", "Typhoon", "Zenith", "Erebus",
      "Bane", "Glint", "Corsair", "Reaver", "Warp", "Titan", "Forge", "Halo", "Glow", "Pulse"
    ];
  
    const last_name = [
      "Ranger", "Carter", "Strider", "Drifter", "Warden", "Fletcher", "Dagger", "Slayer", 
      "Seeker", "Sorcerer", "Vanguard", "Archer", "Paladin", "Crusader", "Rogue", "Falconer", 
      "Beastmaster", "Shadowcaster", "Frostweaver", "Lightbringer", "Nightstalker", "Stormbringer", 
      "Dreadweaver", "Ironfang", "Skullcrusher", "Venomtongue", "Soulreaper", "Bloodhowl", "Wolfrunner",
      "Moonstriker", "Voidcaller", "Flamecaster", "Frostfire", "Skybreaker", "Bonecarver", "Shadowfang",
      "Bladewalker", "Stormwalker", "Pyromancer", "Starwatcher", "Gloryhunter", "Helmseeker", "Thundershield",
      "Steelheart", "Ashbringer", "Windwalker", "Sunstalker", "Blightshadow", "Ghostblade", "Earthshaker",
      "Skywanderer", "Mysticscribe", "Frosthowl", "Warpstalker", "Bladereaper", "Spiritbinder", "Runeseer",
      "Ironbreaker", "Brightarrow", "Soulstealer", "Stormfury", "Nightflame", "Oathkeeper", "Galewarden",
      "Voidshard", "Skyrunner", "Thundersoul", "Lightkeeper", "Shadowhunter", "Grimwalker", "Oathbringer",
      "Sunstorm", "Shadowscythe", "Stoneshield", "Windslasher", "Ironvein", "Spiritcaller", "Starcaller"
    ];
  
    const special_chars = ["_", ".", "-", "~", "*", "", "", ""];
  
    // Select random elements from arrays
    const randomFirstName = first_name[Math.floor(Math.random() * first_name.length)];
    const randomMiddleName = middle_name[Math.floor(Math.random() * middle_name.length)];
    const randomLastName = last_name[Math.floor(Math.random() * last_name.length)];
    const randomSpecialChar = special_chars[Math.floor(Math.random() * special_chars.length)];
    const randomInteger = Math.floor(Math.random() * 1000); // Random number between 0 and 999
  
    const withSpecialChar = Math.random() < 0.5;
  
    // Generate nickname
    const nickName = withSpecialChar
      ? `${randomFirstName}${randomSpecialChar}${randomMiddleName}${randomSpecialChar}${randomLastName}${randomInteger}`
      : `${randomFirstName}${randomMiddleName}${randomLastName}${randomInteger}`;
  
    return nickName;
  };
  
  module.exports = nickNameGenerator;
  