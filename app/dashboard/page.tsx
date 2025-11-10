"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import {
  TrendingUp,
  TrendingDown,
  DollarSign,
  PiggyBank,
  CreditCard,
  RefreshCw,
  Moon,
  Sun,
  UtensilsCrossed,
  Car,
  ShoppingBag,
  Home,
  Search,
  Bell,
} from "lucide-react"
import { ExpenseChart } from "@/components/expense-chart"
import { AIRecommendations } from "@/components/ai-recommendations"
import { AddExpenseForm } from "@/components/add-expense-form"
import { AddIncomeForm } from "@/components/add-income-form"
import { MoneyMascot } from "@/components/money-mascot"
import { ExpenseCalendar } from "@/components/expense-calendar"
import { StreakTracker } from "@/components/streak-tracker"
import { ExpenseList } from "@/components/expense-list"
import { Input } from "@/components/ui/input"
import { AIChat } from "@/components/ai-chat"
import { TutorialOverlay } from "@/components/tutorial-overlay"

interface Expense {
  category: string
  amount: number
  description: string
  date: Date
  photoUrl?: string
  location?: string
  amountSaved?: number
}

interface Income {
  source: string
  amount: number
  description: string
  date: Date
}

interface TutorialStep {
  waitForDialog: boolean
  pointerTarget?: string
  action: string
}

export default function DashboardPage() {
  const router = useRouter()
  const [userName] = useState("María García")
  const [balance, setBalance] = useState(0)
  const [totalSavingsFromAI, setTotalSavingsFromAI] = useState(0)
  const [savings, setSavings] = useState(0)
  const [monthlyExpenses, setMonthlyExpenses] = useState(0)
  const [incomes, setIncomes] = useState<Income[]>([])
  const [userExpenses, setUserExpenses] = useState<Expense[]>([])
  const [showResetConfirm, setShowResetConfirm] = useState(false)
  const [showAddMoney, setShowAddMoney] = useState(false)
  const [addMoneyAmount, setAddMoneyAmount] = useState("")
  const [isDarkMode, setIsDarkMode] = useState(false)
  const [chatCategory, setChatCategory] = useState<string | null>(null)
  const [showNavBar, setShowNavBar] = useState(false)
  const [showTutorial, setShowTutorial] = useState(false)
  const [notifications, setNotifications] = useState<Array<{ id: string; message: string; category: string }>>([])
  const [showNotifications, setShowNotifications] = useState(false)
  const [currentStep, setCurrentStep] = useState<TutorialStep | null>(null)
  const [mainSavingsGoal, setMainSavingsGoal] = useState<number | null>(null)

  useEffect(() => {
    const hasSeenTutorial = localStorage.getItem("hasSeenTutorial")
    if (!hasSeenTutorial) {
      setTimeout(() => setShowTutorial(true), 500)
    }
  }, [])

  useEffect(() => {
    playSound("enter")
  }, [])

  useEffect(() => {
    const notificationMessages = [
      { message: "🍕 Pizza Hut tiene 2x1 en pizzas medianas hoy", category: "comida" },
      { message: "🛒 Mi Comisariato: 30% descuento en lácteos", category: "compras" },
      { message: "🚌 Descuento en tarjeta de transporte público", category: "transporte" },
      { message: "🍔 KFC: Combo familiar a $12.99", category: "comida" },
      { message: "🏪 Tía: Ofertas en productos de limpieza", category: "hogar" },
    ]

    const interval = setInterval(() => {
      const randomNotification = notificationMessages[Math.floor(Math.random() * notificationMessages.length)]
      const newNotification = {
        id: Date.now().toString(),
        ...randomNotification,
      }
      setNotifications((prev) => [...prev, newNotification].slice(-5)) // Mantener solo las últimas 5
    }, 45000) // Cada 45 segundos

    return () => clearInterval(interval)
  }, [])

  useEffect(() => {
    if (!currentStep || !currentStep.waitForDialog) return

    const checkDialog = setInterval(() => {
      const targetElement = document.getElementById(currentStep.pointerTarget!)
      if (targetElement && targetElement.offsetParent !== null) {
        clearInterval(checkDialog)
        // El diálogo está abierto, ahora el usuario puede interactuar
        setTimeout(() => {
          window.dispatchEvent(new CustomEvent("tutorial-action", { detail: { action: currentStep.action } }))
        }, 200)
      }
    }, 100)

    return () => clearInterval(checkDialog)
  }, [currentStep])

  const playSound = (type: "add" | "remove" | "success" | "enter") => {
    if (typeof window === "undefined") return

    const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)()
    const oscillator = audioContext.createOscillator()
    const oscillator2 = audioContext.createOscillator()
    const gainNode = audioContext.createGain()
    const gainNode2 = audioContext.createGain()

    oscillator.connect(gainNode)
    oscillator2.connect(gainNode2)
    gainNode.connect(audioContext.destination)
    gainNode2.connect(audioContext.destination)

    switch (type) {
      case "add":
        // Sonido de monedas cayendo - múltiples tonos
        oscillator.frequency.value = 880
        oscillator2.frequency.value = 1100
        gainNode.gain.setValueAtTime(0.2, audioContext.currentTime)
        gainNode2.gain.setValueAtTime(0.15, audioContext.currentTime)
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3)
        gainNode2.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.35)
        oscillator2.start(audioContext.currentTime + 0.05)
        oscillator2.stop(audioContext.currentTime + 0.4)
        break
      case "remove":
        // Sonido de cajero/máquina registradora
        oscillator.frequency.value = 300
        oscillator2.frequency.value = 250
        gainNode.gain.setValueAtTime(0.25, audioContext.currentTime)
        gainNode2.gain.setValueAtTime(0.2, audioContext.currentTime)
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.2)
        gainNode2.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.25)
        oscillator.frequency.exponentialRampToValueAtTime(200, audioContext.currentTime + 0.15)
        oscillator2.start(audioContext.currentTime + 0.08)
        oscillator2.stop(audioContext.currentTime + 0.3)
        break
      case "success":
        // Sonido de éxito - campanitas
        oscillator.frequency.value = 1047
        oscillator2.frequency.value = 1319
        gainNode.gain.setValueAtTime(0.2, audioContext.currentTime)
        gainNode2.gain.setValueAtTime(0.15, audioContext.currentTime)
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.4)
        gainNode2.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.45)
        oscillator2.start(audioContext.currentTime + 0.1)
        oscillator2.stop(audioContext.currentTime + 0.5)
        break
      case "enter":
        // Sonido de bienvenida
        oscillator.frequency.value = 523
        oscillator2.frequency.value = 659
        gainNode.gain.setValueAtTime(0.15, audioContext.currentTime)
        gainNode2.gain.setValueAtTime(0.1, audioContext.currentTime)
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3)
        gainNode2.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.35)
        oscillator2.start(audioContext.currentTime + 0.1)
        oscillator2.stop(audioContext.currentTime + 0.4)
        break
    }

    oscillator.start(audioContext.currentTime)
    oscillator.stop(audioContext.currentTime + 0.5)
  }

  const handleTutorialComplete = () => {
    // Resetear todos los datos del tutorial
    setBalance(0)
    setMonthlyExpenses(0)
    setSavings(0)
    setTotalSavingsFromAI(0)
    setUserExpenses([])
    setIncomes([])

    localStorage.setItem("hasSeenTutorial", "true")
    setShowTutorial(false)
  }

  const handleAddExpense = (expense: {
    category: string
    amount: number
    description: string
    date: Date
    photoUrl?: string
    location?: string
    amountSaved?: number
  }) => {
    setUserExpenses([...userExpenses, expense])
    setMonthlyExpenses(monthlyExpenses + expense.amount)
    setBalance(balance - expense.amount)

    if (expense.amountSaved && expense.amountSaved > 0) {
      setSavings(savings + expense.amountSaved)
      setTotalSavingsFromAI(totalSavingsFromAI + expense.amountSaved)
    }

    playSound("remove")

    window.dispatchEvent(new CustomEvent("tutorial-action", { detail: { action: "add-expense" } }))
  }

  const handleAddIncome = (income: Income) => {
    setIncomes([...incomes, income])
    setBalance(balance + income.amount)

    playSound("add")
  }

  const handleDeleteExpense = (index: number) => {
    const expense = userExpenses[index]
    setMonthlyExpenses(monthlyExpenses - expense.amount)
    setBalance(balance + expense.amount)
    setUserExpenses(userExpenses.filter((_, i) => i !== index))

    playSound("remove")
  }

  const handleResetExpenses = () => {
    setBalance(0)
    setMonthlyExpenses(0)
    setSavings(0)
    setTotalSavingsFromAI(0)
    setUserExpenses([])
    setIncomes([])
    setShowResetConfirm(false)
  }

  const handleAddMoney = () => {
    if (addMoneyAmount && !isNaN(Number(addMoneyAmount))) {
      const amount = Number(addMoneyAmount)
      setBalance(balance + amount)
      setShowAddMoney(false)
      setAddMoneyAmount("")

      playSound("add")

      setTimeout(() => {
        window.dispatchEvent(new CustomEvent("tutorial-action", { detail: { action: "add-money" } }))
      }, 100)
    }
  }

  const handleAcceptSavings = (savingsAmount: number) => {
    setTotalSavingsFromAI(totalSavingsFromAI + savingsAmount)
    setSavings(savings + savingsAmount)

    playSound("success")
  }

  const toggleDarkMode = () => {
    setIsDarkMode(!isDarkMode)
    document.documentElement.classList.toggle("dark")
  }

  const openChatWithCategory = (category: string) => {
    setChatCategory(category)
    setShowNavBar(false)
  }

  const handleNotificationClick = (notification: { id: string; message: string; category: string }) => {
    setShowNotifications(false)
    const establishmentMatch = notification.message.match(/^[^\w]*(.*?)(?::|tiene|:\s)/)
    const establishment = establishmentMatch ? establishmentMatch[1].trim() : notification.category

    setChatCategory(notification.category)
    // Guardar el filtro de búsqueda para mostrar solo ese establecimiento
    sessionStorage.setItem("chatFilterBy", establishment)

    // Remover la notificación al hacer clic
    setNotifications((prev) => prev.filter((n) => n.id !== notification.id))
  }

  const formatLargeNumber = (num: number): string => {
    if (num >= 1000000000) {
      return (num / 1000000000).toFixed(1) + " billones"
    }
    if (num >= 1000000) {
      return (num / 1000000).toFixed(1) + " millones"
    }
    if (num >= 1000) {
      return (num / 1000).toFixed(1) + " mil"
    }
    return num.toLocaleString("es-EC", { minimumFractionDigits: 2 })
  }

  return (
    <div className="min-h-screen bg-background">
      {showTutorial && <TutorialOverlay onComplete={handleTutorialComplete} />}

      <header className="border-b border-border bg-card sticky top-0 z-50 backdrop-blur-sm">
        <div className="container mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Link href="/" className="flex items-center gap-2">
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-2xl font-bold text-white">
                $
              </div>
              <span className="text-xl font-bold bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent hidden sm:inline">
                AhorraMax
              </span>
            </Link>
          </div>

          <div className="flex items-center gap-2">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setShowNavBar(!showNavBar)}
              className="rounded-xl hover:bg-primary/10 font-medium flex items-center gap-2"
            >
              <Search className="w-4 h-4" />
              <span className="hidden sm:inline">Buscar</span>
            </Button>
            <Button
              variant="ghost"
              size="icon"
              onClick={toggleDarkMode}
              className="rounded-xl hover:bg-primary/10"
              title="Cambiar modo"
            >
              {isDarkMode ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </Button>
            <div className="relative">
              <Button
                variant="ghost"
                size="icon"
                onClick={() => setShowNotifications(!showNotifications)}
                className="rounded-xl hover:bg-primary/10 relative"
                title="Notificaciones de ofertas"
              >
                <Bell className="w-5 h-5" />
                {notifications.length > 0 && (
                  <span className="absolute -top-1 -right-1 w-5 h-5 bg-red-500 text-white text-xs font-bold rounded-full flex items-center justify-center animate-pulse">
                    {notifications.length}
                  </span>
                )}
              </Button>

              {showNotifications && (
                <div className="absolute right-0 top-full mt-2 w-80 bg-card border-2 border-primary/20 rounded-2xl shadow-2xl p-4 animate-in slide-in-from-top-5 duration-300 max-h-96 overflow-y-auto">
                  <h3 className="font-bold text-lg text-foreground mb-3 flex items-center gap-2">
                    <Bell className="w-5 h-5 text-primary" />
                    Ofertas Cerca de Ti
                  </h3>
                  {notifications.length === 0 ? (
                    <p className="text-sm text-muted-foreground text-center py-4">No hay notificaciones nuevas</p>
                  ) : (
                    <div className="space-y-3">
                      {notifications.map((notif) => (
                        <div
                          key={notif.id}
                          className="p-3 rounded-xl bg-primary/10 border border-primary/30 hover:bg-primary/20 transition-colors cursor-pointer"
                          onClick={() => handleNotificationClick(notif)}
                        >
                          <p className="text-sm font-medium text-foreground">{notif.message}</p>
                          <p className="text-xs text-muted-foreground mt-1">Toca para más detalles en el chat IA</p>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </div>
            <Link href="/profile">
              <Avatar className="w-9 h-9 border-2 border-primary cursor-pointer hover:scale-105 transition-transform">
                <AvatarImage src="/placeholder.svg?height=36&width=36" />
                <AvatarFallback className="bg-primary text-white text-sm">MG</AvatarFallback>
              </Avatar>
            </Link>
          </div>
        </div>

        {showNavBar && (
          <div className="border-t border-border bg-card/95 backdrop-blur-sm animate-in slide-in-from-top-5 duration-300">
            <div className="container mx-auto px-4 py-4">
              <h3 className="text-sm font-semibold text-muted mb-3">¿Qué estás buscando?</h3>
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                <Button
                  variant="outline"
                  onClick={() => openChatWithCategory("comida")}
                  className="rounded-xl h-auto py-3 flex flex-col items-center gap-2 hover:bg-primary/10 hover:border-primary"
                >
                  <UtensilsCrossed className="w-6 h-6 text-primary" />
                  <span className="text-sm font-medium">Comida</span>
                </Button>
                <Button
                  variant="outline"
                  onClick={() => openChatWithCategory("transporte")}
                  className="rounded-xl h-auto py-3 flex flex-col items-center gap-2 hover:bg-primary/10 hover:border-primary"
                >
                  <Car className="w-6 h-6 text-primary" />
                  <span className="text-sm font-medium">Transporte</span>
                </Button>
                <Button
                  variant="outline"
                  onClick={() => openChatWithCategory("compras")}
                  className="rounded-xl h-auto py-3 flex flex-col items-center gap-2 hover:bg-primary/10 hover:border-primary"
                >
                  <ShoppingBag className="w-6 h-6 text-primary" />
                  <span className="text-sm font-medium">Compras</span>
                </Button>
                <Button
                  variant="outline"
                  onClick={() => openChatWithCategory("salud")}
                  className="rounded-xl h-auto py-3 flex flex-col items-center gap-2 hover:bg-primary/10 hover:border-primary"
                >
                  <svg className="w-6 h-6 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
                    />
                  </svg>
                  <span className="text-sm font-medium">Salud</span>
                </Button>
                <Button
                  variant="outline"
                  onClick={() => openChatWithCategory("entretenimiento")}
                  className="rounded-xl h-auto py-3 flex flex-col items-center gap-2 hover:bg-primary/10 hover:border-primary"
                >
                  <svg className="w-6 h-6 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M7 4v16M17 4v16M3 8h4m10 0h4M3 12h18M3 16h4m10 0h4M4 20h16a1 1 0 001-1V5a1 1 0 00-1-1H4a1 1 0 00-1 1v14a1 1 0 001 1z"
                    />
                  </svg>
                  <span className="text-sm font-medium">Entretenimiento</span>
                </Button>
                <Button
                  variant="outline"
                  onClick={() => openChatWithCategory("educacion")}
                  className="rounded-xl h-auto py-3 flex flex-col items-center gap-2 hover:bg-primary/10 hover:border-primary"
                >
                  <svg className="w-6 h-6 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13M3 18h4a2 2 0 002 2h4a2 2 0 002-2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                    />
                  </svg>
                  <span className="text-sm font-medium">Educación</span>
                </Button>
                <Button
                  variant="outline"
                  onClick={() => openChatWithCategory("servicios")}
                  className="rounded-xl h-auto py-3 flex flex-col items-center gap-2 hover:bg-primary/10 hover:border-primary"
                >
                  <svg className="w-6 h-6 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                    />
                  </svg>
                  <span className="text-sm font-medium">Servicios</span>
                </Button>
                <Button
                  variant="outline"
                  onClick={() => openChatWithCategory("hogar")}
                  className="rounded-xl h-auto py-3 flex flex-col items-center gap-2 hover:bg-primary/10 hover:border-primary"
                >
                  <Home className="w-6 h-6 text-primary" />
                  <span className="text-sm font-medium">Hogar</span>
                </Button>
              </div>
            </div>
          </div>
        )}
      </header>

      <div className="container mx-auto px-4 py-6 md:py-8 space-y-6">
        <div className="space-y-2">
          <h1 className="text-2xl md:text-3xl font-bold text-foreground">Hola, {userName}</h1>
          <p className="text-muted-foreground">Aquí está tu resumen financiero de hoy</p>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <Card
            className="p-6 bg-gradient-to-br from-primary to-primary-dark text-white border-0 relative"
            id="balance-section"
          >
            <div className="flex items-start justify-between mb-4">
              <div className="w-12 h-12 rounded-2xl bg-white/20 flex items-center justify-center">
                <DollarSign className="w-6 h-6" />
              </div>
              <div className="flex gap-2">
                <Button
                  id="balance-add-btn"
                  size="icon"
                  variant="ghost"
                  onClick={() => setShowAddMoney(true)}
                  className="w-8 h-8 rounded-xl bg-white/20 hover:bg-white/30 text-white"
                  title="Agregar más dinero"
                >
                  <span className="text-lg font-bold">+</span>
                </Button>
                <Button
                  size="icon"
                  variant="ghost"
                  onClick={() => setShowResetConfirm(true)}
                  className="w-8 h-8 rounded-xl bg-white/20 hover:bg-white/30 text-white"
                  title="Resetear todo"
                >
                  <RefreshCw className="w-4 h-4" />
                </Button>
              </div>
            </div>
            <p className="text-white/80 text-sm mb-1">Dinero Actual</p>
            <p className="text-3xl font-bold">${formatLargeNumber(balance)}</p>
          </Card>

          <Card className="p-6 bg-gradient-to-br from-secondary to-primary text-white border-0" id="ahorros-section">
            <div className="flex items-start justify-between mb-4">
              <div className="w-12 h-12 rounded-2xl bg-white/20 flex items-center justify-center">
                <PiggyBank className="w-6 h-6" />
              </div>
              <TrendingUp className="w-5 h-5 text-white/80" />
            </div>
            <p className="text-white/80 text-sm mb-1">Ahorros Totales</p>
            <p className="text-3xl font-bold">${savings.toLocaleString("es-EC", { minimumFractionDigits: 2 })}</p>
            {totalSavingsFromAI > 0 && (
              <p className="text-xs bg-gradient-to-br from-primary to-secondary bg-clip-text text-transparent mt-2 font-medium">
                Has ahorrado ${totalSavingsFromAI.toFixed(2)} con recomendaciones de IA ✨
              </p>
            )}
          </Card>

          <Card
            className="p-6 bg-gradient-to-br from-red-500 to-red-600 text-white border-0"
            onClick={() => {
              const expensesList = document.getElementById("expenses-list")
              if (expensesList) {
                expensesList.scrollIntoView({ behavior: "smooth", block: "center" })
              }
            }}
          >
            <div className="flex items-start justify-between mb-4">
              <div className="w-12 h-12 rounded-2xl bg-white/20 flex items-center justify-center">
                <CreditCard className="w-6 h-6" />
              </div>
              <TrendingDown className="w-5 h-5 text-white/80" />
            </div>
            <p className="text-white/80 text-sm mb-1">Gastos del Mes</p>
            <p className="text-3xl font-bold">
              ${monthlyExpenses.toLocaleString("es-EC", { minimumFractionDigits: 2 })}
            </p>
            <p className="text-xs text-white/70 mt-2">Haz clic para ver detalles</p>
          </Card>
        </div>

        <Card className="p-6 bg-gradient-to-br from-accent/20 to-primary/20 border-2 border-accent/30">
          <div className="flex items-start justify-between mb-4">
            <div>
              <h3 className="text-xl font-bold text-foreground flex items-center gap-2">
                <PiggyBank className="w-6 h-6 text-accent" />
                Tu Meta de Ahorro
              </h3>
              <p className="text-sm text-muted-foreground mt-1">Basado en tu balance actual</p>
            </div>
          </div>

          <div className="space-y-4">
            {balance > 0 && (
              <>
                <div className="p-4 rounded-xl bg-white/50 dark:bg-white/5 border border-accent/20">
                  <p className="text-sm text-muted-foreground mb-2">Balance Actual</p>
                  <p className="text-2xl font-bold text-foreground">${formatLargeNumber(balance)}</p>
                </div>

                {/* Sugerencias dinámicas según el balance */}
                <div className="space-y-2">
                  <p className="text-sm font-semibold text-foreground">Sugerencias para ti:</p>
                  {balance < 100 && (
                    <div className="p-3 rounded-xl bg-primary/10 border border-primary/30">
                      <p className="text-sm text-foreground">
                        💡 <span className="font-bold">${(100 - balance).toFixed(2)} más</span> y tendrás{" "}
                        <span className="font-bold">$100</span> - perfecto para una comida especial
                      </p>
                    </div>
                  )}
                  {balance >= 100 && balance < 200 && (
                    <div className="p-3 rounded-xl bg-secondary/10 border border-secondary/30">
                      <p className="text-sm text-foreground">
                        🎯 Con <span className="font-bold">${balance.toFixed(2)}</span> puedes comprar{" "}
                        <span className="font-bold">una cena para dos</span> en un buen restaurante
                      </p>
                    </div>
                  )}
                  {balance >= 200 && balance < 400 && (
                    <div className="p-3 rounded-xl bg-accent/10 border border-accent/30">
                      <p className="text-sm text-foreground">
                        ⭐ <span className="font-bold">${(400 - balance).toFixed(2)} más</span> y tendrás{" "}
                        <span className="font-bold">$400</span> - suficiente para un electrodoméstico útil
                      </p>
                    </div>
                  )}
                  {balance >= 400 && balance < 1000 && (
                    <div className="p-3 rounded-xl bg-green-500/10 border border-green-500/30">
                      <p className="text-sm text-foreground">
                        🏆 Con <span className="font-bold">${balance.toFixed(2)}</span> puedes comprar{" "}
                        <span className="font-bold">una refrigeradora o TV</span> de buena calidad
                      </p>
                    </div>
                  )}
                  {balance >= 1000 && (
                    <div className="p-3 rounded-xl bg-primary/10 border border-primary/30">
                      <p className="text-sm text-foreground">
                        💎 ¡Excelente! Con <span className="font-bold">${formatLargeNumber(balance)}</span> puedes
                        comprar <span className="font-bold">electrodomésticos premium, muebles o invertir</span>
                      </p>
                    </div>
                  )}
                </div>

                <div className="p-4 rounded-xl bg-gradient-to-r from-primary/20 to-secondary/20 border border-primary/30">
                  <p className="text-xs text-muted-foreground mb-1">Progreso acumulado</p>
                  <div className="w-full h-2 bg-white/20 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-primary to-secondary transition-all duration-300"
                      style={{ width: `${Math.min((balance / 1000) * 100, 100)}%` }}
                    ></div>
                  </div>
                  <p className="text-xs text-muted-foreground mt-2">
                    {balance < 1000 ? `${(balance / 10).toFixed(0)}% hacia $1000` : "¡Meta de $1000 alcanzada!"}
                  </p>
                </div>
              </>
            )}
            {balance === 0 && (
              <div className="p-4 rounded-xl bg-muted/20 border border-border text-center">
                <p className="text-sm text-muted-foreground">
                  Comienza agregando dinero a tu balance para ver sugerencias personalizadas
                </p>
              </div>
            )}
          </div>
        </Card>

        <Card className="p-6 bg-gradient-to-br from-amber-100 to-amber-50 border-2 border-amber-300/50">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-bold text-foreground flex items-center gap-2">
              <PiggyBank className="w-6 h-6 text-amber-600" />
              Meta de Ahorro Principal
            </h3>
            <input
              type="number"
              id="main-savings-goal-input"
              placeholder="¿Cuánto quieres ahorrar?"
              className="px-3 py-1 rounded-lg text-sm border-2 border-amber-300 focus:outline-none focus:border-amber-500 w-32"
              onInput={(e) => {
                const value = Number((e.target as HTMLInputElement).value)
                if (value > 0) {
                  window.dispatchEvent(new CustomEvent("tutorial-action", { detail: { action: "enter-savings-goal" } }))
                }
              }}
            />
          </div>

          {balance > 0 && (
            <div className="space-y-4">
              <div className="grid sm:grid-cols-2 gap-4">
                <div className="p-4 rounded-xl bg-white border border-amber-200">
                  <p className="text-xs text-muted-foreground mb-1">Tu Meta</p>
                  <p className="text-2xl font-bold text-foreground">
                    ${(balance * 2 || 0).toLocaleString("es-EC", { minimumFractionDigits: 2 })}
                  </p>
                  <p className="text-xs text-muted-foreground mt-1">Ahorrar el doble de lo que tienes</p>
                </div>
                <div className="p-4 rounded-xl bg-white border border-amber-200">
                  <p className="text-xs text-muted-foreground mb-1">Progreso</p>
                  <p className="text-2xl font-bold text-amber-600">
                    ${balance.toLocaleString("es-EC", { minimumFractionDigits: 2 })}
                  </p>
                  <p className="text-xs text-muted-foreground mt-1">Tienes ahorrado hasta ahora</p>
                </div>
              </div>

              <div className="p-4 rounded-xl bg-gradient-to-r from-amber-400/20 to-orange-400/20 border border-amber-300">
                <p className="text-sm font-semibold text-foreground mb-3">Recomendaciones con IA:</p>
                <div className="space-y-2 text-sm text-foreground">
                  {balance >= 100 && balance < 200 && (
                    <p>
                      💡 Con ${(balance * 2).toFixed(0)} puedes comprarte un{" "}
                      <span className="font-bold">microondas</span> - revisa las ofertas en Mi Comisariato hoy
                    </p>
                  )}
                  {balance >= 200 && balance < 400 && (
                    <p>
                      🎯 Con ${(balance * 2).toFixed(0)} puedes comprar una{" "}
                      <span className="font-bold">refrigeradora pequeña</span> - hay descuento en Tía este fin de semana
                    </p>
                  )}
                  {balance >= 400 && (
                    <p>
                      ⭐ Con ${(balance * 2).toFixed(0)} puedes invertir en{" "}
                      <span className="font-bold">equipos electrónicos premium</span> - aprovecha la promoción 2x1 de
                      hoy
                    </p>
                  )}
                </div>
              </div>
            </div>
          )}
        </Card>

        <div className="grid lg:grid-cols-2 gap-6">
          <AddExpenseForm onAddExpense={handleAddExpense} />
          <AddIncomeForm onAddIncome={handleAddIncome} />
        </div>

        <ExpenseCalendar expenses={userExpenses} />
        <StreakTracker />

        <div id="recommendations-section">
          <AIRecommendations expenses={userExpenses} onAcceptSavings={handleAcceptSavings} />
        </div>

        <div id="expenses-list">
          <ExpenseList expenses={userExpenses} onDeleteExpense={handleDeleteExpense} />
        </div>

        <div className="grid lg:grid-cols-2 gap-6">
          <ExpenseChart expenses={userExpenses} />
        </div>
      </div>

      <AIChat initialCategory={chatCategory} />
      <MoneyMascot />

      {showAddMoney && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm animate-in fade-in duration-300">
          <div className="bg-card p-6 rounded-3xl shadow-2xl max-w-md mx-4 text-center animate-in zoom-in duration-300 border-2 border-primary/20">
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center">
              <DollarSign className="w-8 h-8 text-white" />
            </div>

            <h3 className="text-2xl font-bold mb-3 text-foreground">Agregar más dinero</h3>
            <p className="text-muted-foreground mb-6">Ingresa la cantidad que quieres agregar a tu balance actual</p>

            <Input
              id="add-money-input"
              type="number"
              placeholder="Ingresa cantidad"
              value={addMoneyAmount}
              onChange={(e) => {
                setAddMoneyAmount(e.target.value)
                if (e.target.value) {
                  window.dispatchEvent(new CustomEvent("tutorial-action", { detail: { action: "enter-amount" } }))
                }
              }}
              className="mb-6 rounded-xl h-12 text-center text-xl font-bold"
            />

            <div className="flex gap-3">
              <Button
                variant="outline"
                onClick={() => {
                  setShowAddMoney(false)
                  setAddMoneyAmount("")
                }}
                className="flex-1 rounded-xl py-6 font-bold"
              >
                Cancelar
              </Button>
              <Button
                id="add-money-submit"
                onClick={() => {
                  handleAddMoney()
                  setTimeout(() => {
                    window.dispatchEvent(new CustomEvent("tutorial-action", { detail: { action: "click-add-button" } }))
                  }, 100)
                }}
                className="flex-1 rounded-xl py-6 font-bold bg-gradient-to-r from-primary to-secondary text-white hover:scale-[1.02] transition-transform"
              >
                Agregar
              </Button>
            </div>
          </div>
        </div>
      )}

      {showResetConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm animate-in fade-in duration-300">
          <div className="bg-card p-6 rounded-3xl shadow-2xl max-w-md mx-4 text-center animate-in zoom-in duration-300 border-2 border-red-500/20">
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-gradient-to-br from-red-400 to-red-600 flex items-center justify-center">
              <RefreshCw className="w-8 h-8 text-white" />
            </div>

            <h3 className="text-2xl font-bold mb-3 text-foreground">¿Seguro quieres resetear todo?</h3>
            <p className="text-muted-foreground mb-6">
              Esta acción eliminará todos tus {userExpenses.length} gastos y {incomes.length} ingresos registrados. Esta
              acción no se puede deshacer.
            </p>

            <div className="flex gap-3">
              <Button
                variant="outline"
                onClick={() => setShowResetConfirm(false)}
                className="flex-1 rounded-xl py-6 font-bold"
              >
                Cancelar
              </Button>
              <Button
                onClick={handleResetExpenses}
                className="flex-1 rounded-xl py-6 font-bold bg-gradient-to-r from-red-500 to-red-600 text-white hover:scale-[1.02] transition-transform"
              >
                Sí, Resetear
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
