import React, { useState, useEffect, useRef } from 'react'
import { 
  Sparkles, Shield, Compass, Hammer, ShieldAlert, 
  Award, RefreshCw, Eye, HelpCircle, Activity,
  Users, BookOpen, Heart, Flame, Droplet, Trees, Moon, Zap, Swords
} from 'lucide-react'
import * as echarts from 'echarts'

// --- GAME DESIGN CONSTANTS & ENGINE CORE ---
const ELEMENTS = {
  WOOD: { name: 'Wood', color: '#10b981', terrain: 'Jungle' },
  SUN: { name: 'Sun', color: '#f59e0b', terrain: 'Meadow' },
  FIRE: { name: 'Fire', color: '#ef4444', terrain: 'Mountain' },
  WATER: { name: 'Water', color: '#3b82f6', terrain: 'Lake' },
  ETHER: { name: 'Ether', color: '#8b5cf6', terrain: 'Swamp' },
  SPIRIT: { name: 'Spirit', color: '#e2e8f0', terrain: 'Shrine' }
}

const CHARACTERS = {
  blacksmith: {
    id: 'blacksmith',
    name: 'The Blacksmith',
    affinity: 'FIRE',
    disaffinity: 'WATER',
    speed: 3,
    backpack: 6,
    signature: 'Pocket Bellows',
    desc: 'Master of metalwork. Smelts at 2:1 up-conversion and yields bonus ores.',
    perks: ['Alloy Smelter: Up-converts metals at 2:1 CE', 'Deep Miner: +1 metal ore on mountains']
  },
  botanist: {
    id: 'botanist',
    name: 'The Botanist',
    affinity: 'WOOD',
    disaffinity: 'ETHER',
    speed: 4,
    backpack: 5,
    signature: "Herbalist's Mortar",
    desc: 'Physician and naturalist. Gains double flora yield and holds unlimited herbs.',
    perks: ['Bountiful Harvest: Double plant gathers', 'Herbal Pocket: Herbs bypass card limit']
  },
  cartographer: {
    id: 'cartographer',
    name: 'The Cartographer',
    affinity: 'WATER',
    disaffinity: 'FIRE',
    speed: 5,
    backpack: 4,
    signature: 'Brass Sextant',
    desc: 'Navigator and mapper. Moves fast and is immune to high Island Rage setbacks.',
    perks: ['Pathfinding: High movement speed', 'Foresight: Immune to Rage card-discard penalty']
  },
  outcast: {
    id: 'outcast',
    name: 'The Outcast',
    affinity: 'ETHER',
    disaffinity: 'SUN',
    speed: 4,
    backpack: 5,
    signature: "Thief's Prybar",
    desc: 'Roguish scavenger. Has a 9-card hand limit and fights better at high Rage.',
    perks: ['Deep Pockets: 9-card hand size limit', 'Rage Capitalizer: +1 fight at Rage >= 6']
  }
}

const RECIPES = [
  { id: 'fishbone_needle', name: 'Fishbone Needle', tier: 'Common', element: 'WATER', ceCost: 2, ingredients: { WATER_C: 2 }, effect: 'Repair / craft aid' },
  { id: 'stone_axe', name: 'Stone Axe', tier: 'Common', element: 'FIRE', ceCost: 3, ingredients: { WOOD_C: 2, FIRE_C: 1 }, effect: '+1 Wood Common on gathers' },
  { id: 'honeyglass_lens', name: 'Honeyglass Lens', tier: 'Uncommon', element: 'SUN', ceCost: 6, ingredients: { SUN_U: 1, FIRE_U: 1 }, effect: 'Reveal adjacent face-down tile' },
  { id: 'sporelight_lantern', name: 'Sporelight Lantern', tier: 'Uncommon', element: 'ETHER', ceCost: 6, ingredients: { ETHER_U: 1, WOOD_U: 1 }, effect: 'Enter swamp T2 at full speed' },
  { id: 'bloodvine_snare', name: 'Bloodvine Snare', tier: 'Rare', element: 'WOOD', ceCost: 18, ingredients: { WOOD_R: 1, WOOD_U: 1, WOOD_C: 6 }, effect: 'Fork: Heal ally (+2 Light) OR Rob rival (+2 Dark)' },
  { id: 'stormcaller_drum', name: 'Stormcaller Drum', tier: 'Rare', element: 'WATER', ceCost: 18, ingredients: { WATER_R: 1, WATER_U: 1, WATER_C: 6 }, effect: 'Move a creature to any tile' },
  { id: 'guardians_cradle', name: 'Guardian\'s Cradle', tier: 'Legendary', element: 'SPIRIT', ceCost: 54, ingredients: { SPIRIT_L: 1, FIRE_R: 1, WATER_R: 1, SPIRIT_C: 9 }, effect: 'Revive/shield player (requires gifting)' },
  { id: 'voidcap_mask', name: 'Voidcap Mask', tier: 'Legendary', element: 'ETHER', ceCost: 54, ingredients: { ETHER_L: 1, ETHER_R: 1, ETHER_C: 18 }, effect: 'Hide your Duality Level' }
]

const CREATURES_DATABASE = [
  { id: 'bramblehog', name: 'Bramblehog', tier: 'Common', f: 4, element: 'WOOD', demand: '1 berry', gift: '+2 Wood Commons', bite: '-1 energy' },
  { id: 'reedpecker', name: 'Reedpecker', tier: 'Common', f: 4, element: 'SUN', demand: '1 Reed', gift: 'Peek top Event card', bite: 'Drop 1 Common' },
  { id: 'copper_serpent', name: 'Copper Serpent', tier: 'Uncommon', f: 5, element: 'FIRE', demand: '1 Copper Ore', gift: '+1 Copper Ore', bite: '-2 energy' },
  { id: 'pearl_otter', name: 'Pearl Otter', tier: 'Uncommon', f: 5, element: 'WATER', demand: '1 Shellfish', gift: '+1 Pearl card', bite: '-1 card' },
  { id: 'shadowmoss_panther', name: 'Shadowmoss Panther', tier: 'Rare', f: 7, element: 'ETHER', demand: 'End action immediately', gift: 'Join fight (+7 F next encounter)', bite: 'Lose highest card' },
  { id: 'pale_stag', name: 'The Pale Stag', tier: 'Legendary', f: 8, element: 'SPIRIT', demand: 'Do not gather/fight 2 turns', gift: 'Select 2 cards from top 5', bite: '-2 Light' }
]

// Fate Deck composition
const createFateDeck = () => {
  const cards = [1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 'Spirit', 'Spirit']
  // Shuffle
  for (let i = cards.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [cards[i], cards[j]] = [cards[j], cards[i]];
  }
  return cards
}

function App() {
  const [activeTab, setActiveTab] = useState('simulator')
  
  // Simulator State
  const [character, setCharacter] = useState(CHARACTERS.blacksmith)
  const [turn, setTurn] = useState(1)
  const [energy, setEnergy] = useState(2)
  const [duality, setDuality] = useState(0) // -10 to 10
  const [rage, setRage] = useState(0) // 0 to 10
  const [vp, setVp] = useState(0)
  
  // Inventory (Wooden tokens vs cards)
  const [commons, setCommons] = useState({ WOOD: 2, SUN: 2, FIRE: 2, WATER: 2, ETHER: 2, SPIRIT: 0 })
  const [cards, setCards] = useState([]) // Named cards: { id, name, tier, element, ceValue }
  const [equipped, setEquipped] = useState([])
  const [fateDeck, setFateDeck] = useState(createFateDeck())
  const [discardedFate, setDiscardedFate] = useState([])
  const [simLog, setSimLog] = useState(['Game started. Draw salvage gear to begin.'])
  const [currentEncounter, setCurrentEncounter] = useState(null)
  
  // Monte Carlo State
  const [mcStrategy, setMcStrategy] = useState('balanced')
  const [mcCharacter, setMcCharacter] = useState('blacksmith')
  const [mcRunning, setMcRunning] = useState(false)
  const [mcResults, setMcResults] = useState(null)
  
  // Chance Calculator State
  const [calcCreature, setCalcCreature] = useState(CREATURES_DATABASE[0])
  const [calcGearBonus, setCalcGearBonus] = useState(0)
  const [calcAffinity, setCalcAffinity] = useState(false)
  const [calcEnergySpend, setCalcEnergySpend] = useState(0)
  
  const vpChartRef = useRef(null)
  const dualityChartRef = useRef(null)
  
  // Add log entry helper
  const addLog = (msg) => {
    setSimLog(prev => [msg, ...prev].slice(0, 50))
  }

  // --- REBALANCE LOGIC & ACTIONS ---
  
  const resetGame = (charObj = character) => {
    setCharacter(charObj)
    setTurn(1)
    setEnergy(2)
    setDuality(0)
    setRage(0)
    setVp(0)
    setCommons({ WOOD: 2, SUN: 2, FIRE: 2, WATER: 2, ETHER: 2, SPIRIT: 0 })
    setCards([])
    setEquipped([])
    setFateDeck(createFateDeck())
    setDiscardedFate([])
    setCurrentEncounter(null)
    setSimLog([`Game reset. Playing as ${charObj.name}. Starting energy: 2. Island is peaceful.`])
  }

  const getHandLimit = () => {
    return character.id === 'outcast' ? 9 : 7
  }

  const countAdvancedCards = () => {
    if (character.id === 'botanist') {
      // Botanist's Herbal Pocket perk: organic/plant cards don't count
      return cards.filter(c => c.element !== 'WOOD' && c.element !== 'ETHER').length
    }
    return cards.length
  }

  // EATING FOOD
  const handleEat = () => {
    if (commons.SUN >= 2 || cards.some(c => c.tier === 'Uncommon')) {
      let restored = 0
      let spent = ''
      if (cards.some(c => c.tier === 'Uncommon')) {
        const foodIdx = cards.findIndex(c => c.tier === 'Uncommon')
        spent = cards[foodIdx].name
        setCards(prev => prev.filter((_, idx) => idx !== foodIdx))
        restored = 3
      } else {
        setCommons(prev => ({ ...prev, SUN: prev.SUN - 2 }))
        spent = '2 Grain tokens'
        restored = 1
      }
      setEnergy(prev => Math.min(5, prev + restored))
      addLog(`[Care] Ate ${spent} to restore +${restored} energy.`)
    } else {
      addLog(`[Care] No food available (need 2 Grain tokens or 1 Uncommon card).`)
    }
  }

  // SLEEPING
  const handleSleep = () => {
    setEnergy(prev => Math.min(5, prev + 2))
    addLog(`[Care] Slept. Gained +2 Energy. Skipped Action Phase.`)
    resolveEndTurn(true)
  }

  // GATHER ACTION
  const handleGather = (element, tier) => {
    const isT2 = tier === 'T2'
    let yieldCommons = 2
    
    // Perform gather
    let cardsDrawn = []
    
    // Cartographer or Blacksmith gathering bonuses
    if (character.id === 'blacksmith' && element === 'FIRE') yieldCommons += 1
    if (character.id === 'botanist' && element === 'WOOD') yieldCommons += 2
    
    // Simulate drawing advanced resource card
    const cardOptions = {
      WOOD: [{ name: 'Hardwood', tier: 'Uncommon', ce: 3 }, { name: 'Ironwood', tier: 'Rare', ce: 9 }, { name: 'Worldroot', tier: 'Legendary', ce: 27 }],
      SUN: [{ name: 'Honey', tier: 'Uncommon', ce: 3 }, { name: 'Sunblossom', tier: 'Rare', ce: 9 }, { name: 'Solar Pollen', tier: 'Legendary', ce: 27 }],
      FIRE: [{ name: 'Copper Ore', tier: 'Uncommon', ce: 3 }, { name: 'Fire Crystal', tier: 'Rare', ce: 9 }, { name: 'Heartstone', tier: 'Legendary', ce: 27 }],
      WATER: [{ name: 'Pearl', tier: 'Uncommon', ce: 3 }, { name: 'Stormglass', tier: 'Rare', ce: 9 }, { name: 'Tear of Sea', tier: 'Legendary', ce: 27 }],
      ETHER: [{ name: 'Glowcap', tier: 'Uncommon', ce: 3 }, { name: 'Mooncap', tier: 'Rare', ce: 9 }, { name: 'Voidcap', tier: 'Legendary', ce: 27 }]
    }

    const pool = cardOptions[element]
    let drawn = null
    if (isT2) {
      // T2 draw 2 keep 1
      const d1 = pool[Math.random() < 0.15 ? 2 : Math.random() < 0.6 ? 1 : 0]
      const d2 = pool[Math.random() < 0.15 ? 2 : Math.random() < 0.6 ? 1 : 0]
      // keep better one
      drawn = d1.ce >= d2.ce ? d1 : d2
    } else {
      // T1 draw 75% U, 25% R
      drawn = Math.random() < 0.25 ? pool[1] : pool[0]
    }
    
    const newCard = {
      id: Math.random().toString(36).substr(2, 9),
      name: drawn.name,
      tier: drawn.tier,
      element: element,
      ceValue: drawn.ce
    }
    
    setCommons(prev => ({ ...prev, [element]: prev[element] + yieldCommons }))
    setCards(prev => [...prev, newCard])
    
    addLog(`[Action] Gathered in ${ELEMENTS[element].terrain} (${tier}). Received +${yieldCommons} ${element} tokens and drew [${newCard.name} (${newCard.tier})].`)
    resolveEndTurn()
  }

  // EXPLORE ACTION
  const handleExplore = () => {
    // Add Island Rage
    setRage(prev => Math.min(10, prev + 1))
    
    // Draw event & creature
    const rand = Math.random()
    if (rand < 0.6) {
      // Draw creature
      const db = CREATURES_DATABASE.filter(c => c.tier !== 'Legendary' || duality >= 6)
      const creature = db[Math.floor(Math.random() * db.length)]
      setCurrentEncounter(creature)
      addLog(`[Explore] Explored a new tile. Island Rage +1. Met ${creature.name} (${creature.tier})!`)
    } else {
      // Peaceful Event
      const resourcesDrawn = ['WOOD', 'SUN', 'FIRE', 'WATER', 'ETHER']
      const el = resourcesDrawn[Math.floor(Math.random() * resourcesDrawn.length)]
      setCommons(prev => ({ ...prev, [el]: prev[el] + 1 }))
      addLog(`[Explore] Explored a new tile. Island Rage +1. Found a peaceful clearing: +1 ${el} token.`)
      resolveEndTurn()
    }
  }

  // RESOLVE ENCOUNTER BEFRIEND
  const handleBefriend = () => {
    if (!currentEncounter) return
    
    // Simple verification - meet demand
    let costElement = currentEncounter.element
    if (commons[costElement] >= 2) {
      setCommons(prev => ({ ...prev, [costElement]: prev[costElement] - 2 }))
      setDuality(prev => Math.min(10, prev + 1))
      
      // Draw reward card
      const pool = {
        WOOD: { name: 'Hardwood', tier: 'Uncommon', ce: 3 },
        SUN: { name: 'Honey', tier: 'Uncommon', ce: 3 },
        FIRE: { name: 'Copper Ore', tier: 'Uncommon', ce: 3 },
        WATER: { name: 'Pearl', tier: 'Uncommon', ce: 3 },
        ETHER: { name: 'Glowcap', tier: 'Uncommon', ce: 3 }
      }
      const reward = pool[currentEncounter.element]
      const newCard = {
        id: Math.random().toString(36).substr(2, 9),
        name: reward.name,
        tier: reward.tier,
        element: currentEncounter.element,
        ceValue: reward.ce
      }
      setCards(prev => [...prev, newCard])
      
      addLog(`[Befriend] Satisfied ${currentEncounter.name}'s demand. Paid 2 ${costElement} tokens. Duality shifted +1 Light. Received card: ${newCard.name}.`)
      setCurrentEncounter(null)
      resolveEndTurn()
    } else {
      addLog(`[Befriend] Insufficient tokens to befriend. Need 2 ${costElement} tokens.`)
    }
  }

  // RESOLVE ENCOUNTER FIGHT
  const handleFight = (energySpend = 0) => {
    if (!currentEncounter) return
    if (energy < energySpend) {
      addLog(`[Fight] Not enough energy to spend on focus.`)
      return
    }
    
    // Draw Fate Card
    let deckCopy = [...fateDeck]
    if (deckCopy.length === 0) {
      deckCopy = createFateDeck()
    }
    const rolled = deckCopy.pop()
    const disc = [...discardedFate, rolled]
    setFateDeck(deckCopy)
    setDiscardedFate(disc)
    
    let rollVal = rolled === 'Spirit' ? 6 : rolled
    let modifier = 0
    
    // Gear bonuses
    if (equipped.some(item => item.id === 'stone_axe' && currentEncounter.element === 'WOOD')) modifier += 1
    
    // Character affinities
    if (character.affinity === currentEncounter.element) modifier += 1
    if (character.disaffinity === currentEncounter.element) modifier -= 1
    
    // Outcast Rage bonus
    if (character.id === 'outcast' && rage >= 6) modifier += 1
    
    // Energy Focus modifier
    modifier += energySpend
    
    const finalScore = rollVal + modifier
    const targetF = currentEncounter.f + Math.floor(rage / 3)
    const won = finalScore >= targetF
    
    if (won) {
      // Fight won
      setDuality(prev => Math.max(-10, prev - 1)) // Dark shift
      setVp(prev => prev + 1)
      
      // Draw 2 rewards
      addLog(`[Fight] Drew Fate: ${rolled} (+${modifier} mod) vs F ${targetF}. WON! Gained +1 VP. Duality -1 Dark.`)
    } else {
      // Fight lost -> Bite
      setEnergy(prev => Math.max(0, prev - (rolled === 1 ? 2 : 1)))
      
      // Rage setback
      let rageSetback = ''
      if (rage >= 5 && character.id !== 'cartographer') {
        // Discard card at high Rage
        if (cards.length > 0) {
          const removed = cards[cards.length - 1]
          setCards(prev => prev.slice(0, -1))
          rageSetback = ` Island Rage setback forced discard of [${removed.name}].`
        }
      }
      
      addLog(`[Fight] Drew Fate: ${rolled} (+${modifier} mod) vs F ${targetF}. LOST! Suffered Bite: ${currentEncounter.bite}.${rageSetback}`)
    }
    
    setEnergy(prev => prev - energySpend)
    setCurrentEncounter(null)
    resolveEndTurn()
  }

  // CRAFT ACTION
  const handleCraft = (recipe) => {
    // Check ingredients
    const req = recipe.ingredients
    let meets = true
    
    // Simple check
    Object.keys(req).forEach(key => {
      if (key.endsWith('_C')) {
        const el = key.replace('_C', '')
        if (commons[el] < req[key]) meets = false
      }
    })
    
    if (meets) {
      // Deduct commons
      setCommons(prev => {
        const next = { ...prev }
        Object.keys(req).forEach(key => {
          if (key.endsWith('_C')) {
            const el = key.replace('_C', '')
            next[el] -= req[key]
          }
        })
        return next
      })
      
      // Add equipped
      setEquipped(prev => [...prev, recipe])
      
      // Dark/Light Shifts
      if (recipe.tier === 'Legendary') {
        setDuality(prev => Math.min(10, prev + 2))
      }
      
      addLog(`[Craft] Crafted ${recipe.name} (${recipe.tier}). Required materials deducted.`)
      resolveEndTurn()
    } else {
      addLog(`[Craft] Missing materials for ${recipe.name}.`)
    }
  }

  // MEDITATE ACTION
  const handleMeditate = () => {
    if (energy >= 1) {
      setEnergy(prev => prev - 1)
      setVp(prev => prev + 1)
      setDuality(prev => Math.min(10, prev + 1))
      addLog(`[Care] Meditated. Spent 1 energy. Unlocked learning this turn, +1 Light, +1 VP.`)
    } else {
      addLog(`[Care] Not enough energy to meditate.`)
    }
  }

  // GIVE BACK LIGHT
  const handleGiveBack = () => {
    if (cards.length > 0) {
      const gifted = cards[0]
      setCards(prev => prev.slice(1))
      setDuality(prev => Math.min(10, prev + 2))
      setRage(prev => Math.max(0, prev - 1))
      setVp(prev => prev + 2)
      addLog(`[Altruism] Gifted advanced card [${gifted.name}] to rivals. +2 Light, -1 Island Rage, +2 VP.`)
      resolveEndTurn()
    } else {
      addLog(`[Altruism] No advanced cards to gift.`)
    }
  }

  // END TURN CHECKS
  const resolveEndTurn = (skipped = false) => {
    // Round timer / decay
    setTurn(prev => {
      const next = prev + 1
      
      // Card Limit checks at end of turn
      const advCount = countAdvancedCards()
      const limit = getHandLimit()
      if (advCount > limit) {
        // Discard cards to match limit
        const diff = advCount - limit
        setCards(prevCards => {
          addLog(`[System] Over hand limit (${advCount}/${limit}). Discarded ${diff} advanced card(s).`)
          return prevCards.slice(0, limit)
        })
      }
      
      // Hypocrisy Penalty check
      const disparity = vp - duality
      if (disparity >= 5 && character.id !== 'outcast') {
        const energyLoss = Math.floor(disparity / 5)
        setEnergy(curr => Math.max(0, curr - energyLoss))
        addLog(`[Hypocrisy] VP exceeds Light by ${disparity}. Suffered -${energyLoss} energy penalty.`)
      }
      
      // Increment Island Rage due to temporal decay at start of round
      setRage(currRage => Math.min(10, currRage + 1))
      
      return next
    })
  }

  // --- MONTE CARLO SIMULATOR ---
  const runMonteCarlo = () => {
    setMcRunning(true)
    setTimeout(() => {
      const iterations = 1000
      const histories = []
      let waysWon = { way1: 0, way2: 0, way3: 0, loss: 0 }
      
      for (let i = 0; i < iterations; i++) {
        let simDuality = 0
        let simRage = 0
        let simEnergy = 2
        let simVp = 0
        let simHand = 0
        let simTurn = 1
        
        const history = []
        
        while (simTurn <= 15) {
          // Temporal Rage increment
          simRage = Math.min(10, simRage + 1)
          
          // Decisions based on strategy
          if (mcStrategy === 'altruist') {
            // Focus on gather & gift
            simDuality = Math.min(10, simDuality + 1.2)
            simRage = Math.max(0, simRage - 0.5)
            simVp += 1.5
          } else if (mcStrategy === 'roguish') {
            // Exploit and fight
            simDuality = Math.max(-10, simDuality - 1.5)
            simRage = Math.min(10, simRage + 1.2)
            simVp += 2.2
          } else {
            // Balanced
            simDuality = Math.min(10, Math.max(-10, simDuality + (Math.random() > 0.4 ? 0.5 : -0.5)))
            simRage = Math.min(10, simRage + 0.8)
            simVp += 1.6
          }
          
          history.push({ turn: simTurn, vp: simVp, duality: simDuality, rage: simRage })
          simTurn++
        }
        
        // Determine Win Way
        const endDuality = simDuality
        const endVp = simVp
        
        if (endDuality >= 8 && endVp >= 15) waysWon.way2++
        else if (endDuality >= 3 && endVp >= 25) waysWon.way1++
        else if (endDuality <= -8 && endVp >= 30) waysWon.way3++
        else waysWon.loss++
        
        histories.push(history)
      }
      
      // Calculate averages
      const avgHistory = []
      for (let t = 1; t <= 15; t++) {
        let sumVp = 0, sumDuality = 0, sumRage = 0
        histories.forEach(hist => {
          const step = hist.find(h => h.turn === t)
          if (step) {
            sumVp += step.vp
            sumDuality += step.duality
            sumRage += step.rage
          }
        })
        avgHistory.push({
          turn: t,
          vp: sumVp / iterations,
          duality: sumDuality / iterations,
          rage: sumRage / iterations
        })
      }
      
      setMcResults({ avgHistory, waysWon })
      setMcRunning(false)
    }, 500)
  }

  // Chart Rendering
  useEffect(() => {
    if (activeTab === 'montecarlo' && mcResults) {
      // VP Chart
      const chartVp = echarts.init(vpChartRef.current)
      chartVp.setOption({
        title: { text: 'Economy Engine: VP Pacing (15 Turns)', textStyle: { color: '#f3f4f6' } },
        tooltip: { trigger: 'axis' },
        xAxis: { type: 'category', data: mcResults.avgHistory.map(h => `T${h.turn}`), axisLabel: { color: '#9ca3af' } },
        yAxis: { type: 'value', axisLabel: { color: '#9ca3af' } },
        series: [{
          name: 'Avg VP',
          data: mcResults.avgHistory.map(h => h.vp.toFixed(2)),
          type: 'line',
          smooth: true,
          lineStyle: { color: '#aa3bff', width: 3 }
        }]
      })
      
      // Duality & Rage Chart
      const chartDual = echarts.init(dualityChartRef.current)
      chartDual.setOption({
        title: { text: 'Engine Dynamics: Duality vs. Rage', textStyle: { color: '#f3f4f6' } },
        tooltip: { trigger: 'axis' },
        xAxis: { type: 'category', data: mcResults.avgHistory.map(h => `T${h.turn}`), axisLabel: { color: '#9ca3af' } },
        yAxis: { type: 'value', axisLabel: { color: '#9ca3af' } },
        series: [
          {
            name: 'Avg Duality',
            data: mcResults.avgHistory.map(h => h.duality.toFixed(2)),
            type: 'line',
            smooth: true,
            lineStyle: { color: '#10b981', width: 2 }
          },
          {
            name: 'Avg Island Rage',
            data: mcResults.avgHistory.map(h => h.rage.toFixed(2)),
            type: 'line',
            smooth: true,
            lineStyle: { color: '#ef4444', width: 2 }
          }
        ]
      })
    }
  }, [activeTab, mcResults])

  // --- COMBAT CHANCE CALCULATOR ---
  const calculateWinProbability = () => {
    const f = calcCreature.f + Math.floor(rage / 3)
    let modifier = calcGearBonus + calcEnergySpend
    if (calcAffinity) modifier += 1
    
    // Fate deck composition: 12 cards total
    const fateValues = [1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 6] // Spirit acts as 6
    let wins = 0
    fateValues.forEach(val => {
      if (val + modifier >= f) wins++
    })
    
    return ((wins / fateValues.length) * 100).toFixed(1)
  }

  return (
    <div style={{ padding: '24px', background: '#111216', color: '#e5e7eb', minHeight: '100vh', fontFamily: 'system-ui, sans-serif' }}>
      
      {/* HEADER */}
      <header style={{ borderBottom: '1px solid #2e303a', paddingBottom: '16px', marginBottom: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ margin: 0, fontSize: '28px', background: 'linear-gradient(to right, #a78bfa, #c084fc)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Activity className="animate-pulse" /> Into the Wild: Engine Analyzer
          </h1>
          <p style={{ margin: '4px 0 0', color: '#9ca3af', fontSize: '14px' }}>Expert balancer and simulator dashboard</p>
        </div>
        <div style={{ display: 'flex', gap: '8px' }}>
          <button onClick={() => setActiveTab('simulator')} style={{ padding: '8px 16px', borderRadius: '8px', border: 'none', background: activeTab === 'simulator' ? '#aa3bff' : '#1f2028', color: '#fff', cursor: 'pointer', fontWeight: '500' }}>
            Simulator
          </button>
          <button onClick={() => setActiveTab('montecarlo')} style={{ padding: '8px 16px', borderRadius: '8px', border: 'none', background: activeTab === 'montecarlo' ? '#aa3bff' : '#1f2028', color: '#fff', cursor: 'pointer', fontWeight: '500' }}>
            Monte Carlo
          </button>
          <button onClick={() => setActiveTab('chance')} style={{ padding: '8px 16px', borderRadius: '8px', border: 'none', background: activeTab === 'chance' ? '#aa3bff' : '#1f2028', color: '#fff', cursor: 'pointer', fontWeight: '500' }}>
            Perceived Chance
          </button>
          <button onClick={() => setActiveTab('recipes')} style={{ padding: '8px 16px', borderRadius: '8px', border: 'none', background: activeTab === 'recipes' ? '#aa3bff' : '#1f2028', color: '#fff', cursor: 'pointer', fontWeight: '500' }}>
            Recipes & Specs
          </button>
        </div>
      </header>

      {/* SIMULATOR TAB */}
      {activeTab === 'simulator' && (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 320px', gap: '20px' }}>
          
          {/* Main Controls & Log */}
          <div>
            {/* Status Panel */}
            <div style={{ background: '#1f2028', border: '1px solid #2e303a', borderRadius: '12px', padding: '20px', marginBottom: '20px', display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: '12px' }}>
              <div>
                <span style={{ fontSize: '12px', color: '#9ca3af', textTransform: 'uppercase' }}>Character</span>
                <div style={{ fontSize: '16px', fontWeight: 'bold', color: '#c084fc', marginTop: '4px' }}>{character.name}</div>
              </div>
              <div>
                <span style={{ fontSize: '12px', color: '#9ca3af', textTransform: 'uppercase' }}>Turn / Round</span>
                <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#fff', marginTop: '4px' }}>{turn} / 15</div>
              </div>
              <div>
                <span style={{ fontSize: '12px', color: '#9ca3af', textTransform: 'uppercase' }}>Energy</span>
                <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#f59e0b', marginTop: '4px', display: 'flex', alignItems: 'center', gap: '4px' }}>
                  {Array.from({ length: 5 }).map((_, i) => (
                    <Zap key={i} size={16} fill={i < energy ? '#f59e0b' : 'none'} color={i < energy ? '#f59e0b' : '#4b5563'} />
                  ))}
                </div>
              </div>
              <div>
                <span style={{ fontSize: '12px', color: '#9ca3af', textTransform: 'uppercase' }}>Duality (Light)</span>
                <div style={{ fontSize: '18px', fontWeight: 'bold', color: duality >= 3 ? '#10b981' : duality <= -3 ? '#ef4444' : '#fff', marginTop: '4px' }}>
                  {duality > 0 ? `+${duality} Light` : duality < 0 ? `${duality} Dark` : '0 Neutral'}
                </div>
              </div>
              <div>
                <span style={{ fontSize: '12px', color: '#9ca3af', textTransform: 'uppercase' }}>Island Rage</span>
                <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#ef4444', marginTop: '4px' }}>
                  {rage} / 10
                </div>
              </div>
            </div>

            {/* Turn Actions */}
            <div style={{ background: '#1f2028', border: '1px solid #2e303a', borderRadius: '12px', padding: '20px', marginBottom: '20px' }}>
              <h3 style={{ margin: '0 0 16px', fontSize: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Compass size={18} color="#aa3bff" /> Perform Care Phase Actions
              </h3>
              <div style={{ display: 'flex', gap: '10px', marginBottom: '24px' }}>
                <button onClick={handleEat} style={{ flex: 1, padding: '12px', background: '#3b82f6', border: 'none', borderRadius: '8px', color: '#fff', cursor: 'pointer', fontWeight: 'bold' }}>
                  Eat Food (+1 / +3 Energy)
                </button>
                <button onClick={handleMeditate} style={{ flex: 1, padding: '12px', background: '#8b5cf6', border: 'none', borderRadius: '8px', color: '#fff', cursor: 'pointer', fontWeight: 'bold' }}>
                  Meditate (Unlock Learning)
                </button>
                <button onClick={handleSleep} style={{ flex: 1, padding: '12px', background: '#4b5563', border: 'none', borderRadius: '8px', color: '#fff', cursor: 'pointer', fontWeight: 'bold' }}>
                  Sleep (+2 Energy, Skip Actions)
                </button>
              </div>

              <h3 style={{ margin: '0 0 16px', fontSize: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Hammer size={18} color="#aa3bff" /> Perform Main Actions
              </h3>
              
              {currentEncounter ? (
                <div style={{ background: '#2d1f1f', border: '1px solid #ef4444', borderRadius: '8px', padding: '16px', marginBottom: '16px' }}>
                  <h4 style={{ margin: '0 0 8px', color: '#ef4444' }}>Encounter Alert: {currentEncounter.name} (Fight Number F: {currentEncounter.f + Math.floor(rage / 3)})</h4>
                  <p style={{ margin: '0 0 12px', fontSize: '14px', color: '#d1d5db' }}>Demand: {currentEncounter.demand} | Reward: {currentEncounter.gift} | Bite: {currentEncounter.bite}</p>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button onClick={handleBefriend} style={{ padding: '8px 16px', background: '#10b981', border: 'none', borderRadius: '6px', color: '#fff', fontWeight: 'bold', cursor: 'pointer' }}>
                      Befriend (Pay Demand)
                    </button>
                    <button onClick={() => handleFight(0)} style={{ padding: '8px 16px', background: '#ef4444', border: 'none', borderRadius: '6px', color: '#fff', fontWeight: 'bold', cursor: 'pointer' }}>
                      Fight (Draw Fate)
                    </button>
                    <button onClick={() => handleFight(1)} style={{ padding: '8px 16px', background: '#f59e0b', border: 'none', borderRadius: '6px', color: '#fff', fontWeight: 'bold', cursor: 'pointer' }}>
                      Fight + Spend 1 Energy (+1 Mod)
                    </button>
                  </div>
                </div>
              ) : (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '10px' }}>
                  <button onClick={handleExplore} style={{ padding: '12px', background: '#10b981', border: 'none', borderRadius: '8px', color: '#fff', cursor: 'pointer', fontWeight: 'bold' }}>
                    Explore Tile (+1 Rage)
                  </button>
                  <button onClick={() => handleGather('WOOD', 'T1')} style={{ padding: '12px', background: '#059669', border: 'none', borderRadius: '8px', color: '#fff', cursor: 'pointer', fontWeight: 'bold' }}>
                    Gather T1 Jungle (Wood)
                  </button>
                  <button onClick={() => handleGather('FIRE', 'T2')} style={{ padding: '12px', background: '#dc2626', border: 'none', borderRadius: '8px', color: '#fff', cursor: 'pointer', fontWeight: 'bold' }}>
                    Gather T2 Mountain (Fire)
                  </button>
                  <button onClick={handleGiveBack} style={{ padding: '12px', background: '#d97706', border: 'none', borderRadius: '8px', color: '#fff', cursor: 'pointer', fontWeight: 'bold' }}>
                    Give Back Light (+2 Light, +2 VP)
                  </button>
                  <button onClick={() => handleCraft(RECIPES[1])} style={{ padding: '12px', background: '#3b82f6', border: 'none', borderRadius: '8px', color: '#fff', cursor: 'pointer', fontWeight: 'bold' }}>
                    Craft Stone Axe
                  </button>
                  <button onClick={() => resetGame()} style={{ padding: '12px', background: '#1f2028', border: '1px solid #4b5563', borderRadius: '8px', color: '#fff', cursor: 'pointer', fontWeight: 'bold' }}>
                    Reset Run
                  </button>
                </div>
              )}
            </div>

            {/* Game Logs */}
            <div style={{ background: '#1f2028', border: '1px solid #2e303a', borderRadius: '12px', padding: '20px' }}>
              <h3 style={{ margin: '0 0 12px', fontSize: '16px' }}>Simulator Action Logs</h3>
              <div style={{ background: '#111216', borderRadius: '8px', padding: '12px', maxHeight: '200px', overflowY: 'auto', fontFamily: 'Courier, monospace', fontSize: '13px' }}>
                {simLog.map((log, i) => (
                  <div key={i} style={{ marginBottom: '6px', color: log.startsWith('[Action]') ? '#10b981' : log.startsWith('[Explore]') ? '#c084fc' : '#e5e7eb' }}>
                    {log}
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Right Inventory & Status Panel */}
          <div>
            <div style={{ background: '#1f2028', border: '1px solid #2e303a', borderRadius: '12px', padding: '20px', marginBottom: '20px' }}>
              <h3 style={{ margin: '0 0 12px', fontSize: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Users size={18} color="#aa3bff" /> Choose Character
              </h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                {Object.values(CHARACTERS).map((char) => (
                  <button key={char.id} onClick={() => resetGame(char)} style={{ padding: '10px', background: character.id === char.id ? '#aa3bff' : '#111216', border: '1px solid #2e303a', borderRadius: '8px', color: '#fff', cursor: 'pointer', textAlign: 'left' }}>
                    <div style={{ fontWeight: 'bold' }}>{char.name}</div>
                    <div style={{ fontSize: '11px', color: '#d1d5db', marginTop: '2px' }}>{char.desc}</div>
                  </button>
                ))}
              </div>
            </div>

            {/* Carrying Inventory & Hand Limits */}
            <div style={{ background: '#1f2028', border: '1px solid #2e303a', borderRadius: '12px', padding: '20px' }}>
              <h3 style={{ margin: '0 0 12px', fontSize: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Award size={18} color="#aa3bff" /> Resource Inventory
              </h3>
              
              <div style={{ marginBottom: '16px' }}>
                <div style={{ fontSize: '13px', color: '#9ca3af', marginBottom: '6px' }}>Basic Tokens (Unlimited)</div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '6px' }}>
                  {Object.entries(commons).map(([el, qty]) => (
                    <div key={el} style={{ background: '#111216', padding: '6px', borderRadius: '6px', textAlign: 'center', fontSize: '12px', borderLeft: `3px solid ${ELEMENTS[el]?.color || '#fff'}` }}>
                      {el}: <strong>{qty}</strong>
                    </div>
                  ))}
                </div>
              </div>

              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', color: '#9ca3af', marginBottom: '6px' }}>
                  <span>Advanced Resource Cards</span>
                  <span>{countAdvancedCards()} / {getHandLimit()} Limit</span>
                </div>
                <div style={{ background: '#111216', padding: '8px', borderRadius: '6px', minHeight: '80px', fontSize: '12px' }}>
                  {cards.length === 0 ? (
                    <span style={{ color: '#4b5563' }}>Hand is empty</span>
                  ) : (
                    cards.map(c => (
                      <div key={c.id} style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 0', borderBottom: '1px solid #2e303a' }}>
                        <span style={{ color: ELEMENTS[c.element]?.color }}>{c.name}</span>
                        <span style={{ color: '#9ca3af' }}>{c.tier}</span>
                      </div>
                    ))
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* MONTE CARLO TAB */}
      {activeTab === 'montecarlo' && (
        <div style={{ display: 'grid', gridTemplateColumns: '320px 1fr', gap: '20px' }}>
          {/* Controls */}
          <div style={{ background: '#1f2028', border: '1px solid #2e303a', borderRadius: '12px', padding: '20px' }}>
            <h3 style={{ margin: '0 0 16px', fontSize: '16px' }}>Monte Carlo Parameters</h3>
            
            <div style={{ marginBottom: '16px' }}>
              <label style={{ fontSize: '13px', color: '#9ca3af', display: 'block', marginBottom: '6px' }}>Strategy Profile</label>
              <select value={mcStrategy} onChange={e => setMcStrategy(e.target.value)} style={{ width: '100%', padding: '10px', background: '#111216', border: '1px solid #2e303a', borderRadius: '6px', color: '#fff' }}>
                <option value="balanced">Balanced Explorer</option>
                <option value="altruist">Pure Altruist (Gift Focus)</option>
                <option value="roguish">Roguish Exploiter (Dark Path)</option>
              </select>
            </div>

            <div style={{ marginBottom: '24px' }}>
              <label style={{ fontSize: '13px', color: '#9ca3af', display: 'block', marginBottom: '6px' }}>Test Character</label>
              <select value={mcCharacter} onChange={e => setMcCharacter(e.target.value)} style={{ width: '100%', padding: '10px', background: '#111216', border: '1px solid #2e303a', borderRadius: '6px', color: '#fff' }}>
                {Object.values(CHARACTERS).map(c => (
                  <option key={c.id} value={c.id}>{c.name}</option>
                ))}
              </select>
            </div>

            <button onClick={runMonteCarlo} disabled={mcRunning} style={{ width: '100%', padding: '12px', background: '#aa3bff', border: 'none', borderRadius: '8px', color: '#fff', fontWeight: 'bold', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
              <RefreshCw className={mcRunning ? 'animate-spin' : ''} size={18} />
              {mcRunning ? 'Simulating...' : 'Run 1,000 Game Runs'}
            </button>

            {mcResults && (
              <div style={{ marginTop: '24px', borderTop: '1px solid #2e303a', paddingTop: '16px' }}>
                <h4 style={{ margin: '0 0 12px', fontSize: '14px' }}>Victory Distribution</h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '13px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>Way 1 (Capable/VP):</span>
                    <strong>{((mcResults.waysWon.way1 / 1000) * 100).toFixed(1)}%</strong>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>Way 2 (Enlightened/Light):</span>
                    <strong style={{ color: '#10b981' }}>{((mcResults.waysWon.way2 / 1000) * 100).toFixed(1)}%</strong>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                    <span>Way 3 (Dark Victory):</span>
                    <strong style={{ color: '#ef4444' }}>{((mcResults.waysWon.way3 / 1000) * 100).toFixed(1)}%</strong>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', borderTop: '1px solid #2e303a', paddingTop: '6px' }}>
                    <span>Losses / Stalls:</span>
                    <strong style={{ color: '#f59e0b' }}>{((mcResults.waysWon.loss / 1000) * 100).toFixed(1)}%</strong>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Graphs */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            {mcResults ? (
              <>
                <div ref={vpChartRef} style={{ height: '300px', background: '#1f2028', border: '1px solid #2e303a', borderRadius: '12px', padding: '16px' }}></div>
                <div ref={dualityChartRef} style={{ height: '300px', background: '#1f2028', border: '1px solid #2e303a', borderRadius: '12px', padding: '16px' }}></div>
              </>
            ) : (
              <div style={{ flexGrow: 1, background: '#1f2028', border: '1px solid #2e303a', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', color: '#9ca3af', minHeight: '300px' }}>
                <Activity size={48} style={{ marginBottom: '16px', color: '#4b5563' }} />
                <span>Select parameters and run the Monte Carlo simulation to view charts</span>
              </div>
            )}
          </div>
        </div>
      )}

      {/* CHANCE TAB */}
      {activeTab === 'chance' && (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 360px', gap: '20px' }}>
          {/* Probability Calculator */}
          <div style={{ background: '#1f2028', border: '1px solid #2e303a', borderRadius: '12px', padding: '20px' }}>
            <h3 style={{ margin: '0 0 16px', fontSize: '16px' }}>Perceived Chance & Combat Risk Analyzer</h3>
            <p style={{ fontSize: '14px', color: '#9ca3af', marginBottom: '24px' }}>
              Calculates exact fight win odds using the **12-card Fate Deck** composition vs creature Fight Numbers ($F$).
            </p>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '24px' }}>
              <div>
                <label style={{ fontSize: '13px', color: '#9ca3af', display: 'block', marginBottom: '6px' }}>Select Target Creature</label>
                <select value={calcCreature.id} onChange={e => setCalcCreature(CREATURES_DATABASE.find(c => c.id === e.target.value))} style={{ width: '100%', padding: '10px', background: '#111216', border: '1px solid #2e303a', borderRadius: '6px', color: '#fff' }}>
                  {CREATURES_DATABASE.map(c => (
                    <option key={c.id} value={c.id}>{c.name} (Base F: {c.f})</option>
                  ))}
                </select>
              </div>
              <div>
                <label style={{ fontSize: '13px', color: '#9ca3af', display: 'block', marginBottom: '6px' }}>Island Rage Modifier</label>
                <div style={{ padding: '10px', background: '#111216', border: '1px solid #2e303a', borderRadius: '6px', color: '#fff', fontWeight: 'bold' }}>
                  +{Math.floor(rage / 3)} (Global F modifier)
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '24px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <input type="checkbox" checked={calcAffinity} onChange={e => setCalcAffinity(e.target.checked)} id="affinity" />
                <label htmlFor="affinity" style={{ fontSize: '14px' }}>Character Element Affinity (+1 roll bonus)</label>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <label style={{ fontSize: '14px' }}>Active Weapon/Gear Bonus: </label>
                <input type="number" value={calcGearBonus} onChange={e => setCalcGearBonus(parseInt(e.target.value) || 0)} style={{ width: '60px', padding: '6px', background: '#111216', border: '1px solid #2e303a', borderRadius: '4px', color: '#fff', textAlign: 'center' }} />
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <label style={{ fontSize: '14px' }}>Spend Energy Focus: </label>
                <select value={calcEnergySpend} onChange={e => setCalcEnergySpend(parseInt(e.target.value))} style={{ padding: '6px', background: '#111216', border: '1px solid #2e303a', borderRadius: '4px', color: '#fff' }}>
                  <option value={0}>0 (No Focus)</option>
                  <option value={1}>1 Energy (+1 Mod)</option>
                  <option value={2}>2 Energy (+2 Mod)</option>
                </select>
              </div>
            </div>

            <div style={{ background: '#111216', borderRadius: '8px', padding: '20px', textAlign: 'center' }}>
              <div style={{ fontSize: '14px', color: '#9ca3af', textTransform: 'uppercase' }}>Win Probability</div>
              <div style={{ fontSize: '48px', fontWeight: 'bold', color: parseFloat(calculateWinProbability()) >= 70 ? '#10b981' : parseFloat(calculateWinProbability()) >= 40 ? '#f59e0b' : '#ef4444', margin: '8px 0' }}>
                {calculateWinProbability()}%
              </div>
              <div style={{ fontSize: '12px', color: '#9ca3af' }}>
                Requires final check score of <strong>{calcCreature.f + Math.floor(rage / 3)}</strong> or higher.
              </div>
            </div>
          </div>

          {/* Fate Deck State Info */}
          <div style={{ background: '#1f2028', border: '1px solid #2e303a', borderRadius: '12px', padding: '20px' }}>
            <h3 style={{ margin: '0 0 16px', fontSize: '16px' }}>Fate Deck Distribution</h3>
            <p style={{ fontSize: '13px', color: '#9ca3af', marginBottom: '16px' }}>
              Unlike dice, Fate Cards prevent long "bad luck streaks" and reward tracking what has been played.
            </p>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', marginBottom: '24px' }}>
              {[1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 'Spirit', 'Spirit'].map((val, idx) => {
                const isPlayed = discardedFate.includes(val)
                return (
                  <div key={idx} style={{ flex: '1 1 calc(25% - 8px)', padding: '12px 6px', background: isPlayed ? '#111216' : '#8b5cf6', color: isPlayed ? '#4b5563' : '#fff', border: isPlayed ? '1px dashed #2e303a' : 'none', borderRadius: '6px', textAlign: 'center', fontSize: '13px', fontWeight: 'bold' }}>
                    {val}
                  </div>
                )
              })}
            </div>
            <div style={{ fontSize: '12px', color: '#9ca3af' }}>
              * Spirit cards count as a value of 6 in combat and reward +1 Light instantly.
            </div>
          </div>
        </div>
      )}

      {/* RECIPES TAB */}
      {activeTab === 'recipes' && (
        <div style={{ background: '#1f2028', border: '1px solid #2e303a', borderRadius: '12px', padding: '20px' }}>
          <h3 style={{ margin: '0 0 16px', fontSize: '16px' }}>Balanced Recipe Matrix & CE Budgets</h3>
          <p style={{ fontSize: '14px', color: '#9ca3af', marginBottom: '20px' }}>
            Verify recipes match budgets (Common 2-3, Uncommon ~6, Rare ~18, Legendary ~54 CE).
          </p>

          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '14px', textAlign: 'left' }}>
            <thead>
              <tr style={{ borderBottom: '2px solid #2e303a', color: '#9ca3af' }}>
                <th style={{ padding: '12px' }}>Item Name</th>
                <th style={{ padding: '12px' }}>Tier</th>
                <th style={{ padding: '12px' }}>Element</th>
                <th style={{ padding: '12px' }}>Recipe Cost</th>
                <th style={{ padding: '12px' }}>Ingredients</th>
                <th style={{ padding: '12px' }}>Effect</th>
              </tr>
            </thead>
            <tbody>
              {RECIPES.map(r => (
                <tr key={r.id} style={{ borderBottom: '1px solid #2e303a' }}>
                  <td style={{ padding: '12px', fontWeight: 'bold' }}>{r.name}</td>
                  <td style={{ padding: '12px', color: r.tier === 'Legendary' ? '#f59e0b' : r.tier === 'Rare' ? '#c084fc' : '#9ca3af' }}>{r.tier}</td>
                  <td style={{ padding: '12px', color: ELEMENTS[r.element]?.color }}>{r.element}</td>
                  <td style={{ padding: '12px' }}><strong>{r.ceCost} CE</strong></td>
                  <td style={{ padding: '12px', fontFamily: 'monospace' }}>{Object.entries(r.ingredients).map(([k, v]) => `${k}:${v}`).join(', ')}</td>
                  <td style={{ padding: '12px', color: '#9ca3af' }}>{r.effect}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

export default App
