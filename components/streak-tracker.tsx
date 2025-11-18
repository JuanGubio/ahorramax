"use client"

import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Flame, Trophy, Target, Award, PartyPopper, Edit, Plus, Calendar, Trash2 } from "lucide-react"
import { useState, useEffect } from "react"

interface DailyGoal {
  id: string
  amount: number
  description: string
  date: Date
  completed: boolean
}

export function StreakTracker() {
  const [currentStreak, setCurrentStreak] = useState(7)
  const [bestStreak, setBestStreak] = useState(15)
  const [savingsGoal, setSavingsGoal] = useState(5000)
  const [currentSavings, setCurrentSavings] = useState(3200)
  const [showCelebration, setShowCelebration] = useState(false)
  const [isEditingGoal, setIsEditingGoal] = useState(false)
  const [newGoal, setNewGoal] = useState("")
  const [aiRecommendation, setAiRecommendation] = useState("")
  const [dailyGoals, setDailyGoals] = useState<DailyGoal[]>([])
  const [showAddGoal, setShowAddGoal] = useState(false)
  const [newDailyGoal, setNewDailyGoal] = useState("")
  const [newDailyAmount, setNewDailyAmount] = useState("")

  const progress = (currentSavings / savingsGoal) * 100
  const nextMilestone = Math.ceil(currentStreak / 7) * 7
  const daysToMilestone = nextMilestone - currentStreak

  useEffect(() => {
    if (savingsGoal > 0) {
      fetchAIRecommendation(savingsGoal)
    }
  }, [savingsGoal])

  // Las metas se mantienen hasta que el usuario las elimine manualmente

  const fetchAIRecommendation = async (goal: number) => {
    try {
      const response = await fetch("/api/streak-recommendation", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ currentGoal: goal }),
      })
      const data = await response.json()
      setAiRecommendation(data.recommendation)
    } catch (error) {
      console.error("Error obteniendo recomendación:", error)
      setAiRecommendation(
        `¡Excelente meta de $${goal}! Te recomiendo ahorrar $${(goal * 1.5).toFixed(0)} como siguiente reto.`,
      )
    }
  }

  const handleSetGoal = () => {
    const goal = Number.parseFloat(newGoal)
    if (goal > 0) {
      setSavingsGoal(goal)
      setIsEditingGoal(false)
      setNewGoal("")
    }
  }

  const handleCompleteGoal = () => {
    if (currentSavings >= savingsGoal) {
      return
    }

    setCurrentSavings(savingsGoal)
    setCurrentStreak(currentStreak + 1)
    if (currentStreak + 1 > bestStreak) {
      setBestStreak(currentStreak + 1)
    }
    setShowCelebration(true)

    // Vibración del teléfono
    if (typeof window !== "undefined" && "vibrate" in navigator) {
      navigator.vibrate([200, 100, 200, 100, 400])
    }

    setTimeout(() => {
      setShowCelebration(false)
    }, 5000)
  }

  const handleAddDailyGoal = () => {
    const amount = Number.parseFloat(newDailyAmount)
    if (newDailyGoal && amount > 0) {
      const goal: DailyGoal = {
        id: Date.now().toString(),
        amount,
        description: newDailyGoal,
        date: new Date(),
        completed: false,
      }
      setDailyGoals([...dailyGoals, goal])
      setShowAddGoal(false)
      setNewDailyGoal("")
      setNewDailyAmount("")
    }
  }

  const handleToggleDailyGoal = (id: string) => {
    setDailyGoals(dailyGoals.map((goal) => (goal.id === id ? { ...goal, completed: !goal.completed } : goal)))
  }

  const handleDeleteDailyGoal = (id: string) => {
    setDailyGoals(dailyGoals.filter((goal) => goal.id !== id))
  }

  return (
    <>
      <Card className="p-6 bg-gradient-to-br from-primary/10 via-secondary/10 to-accent/10 border-2 border-primary/20 overflow-hidden relative">
        <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-primary/20 to-secondary/20 rounded-full blur-3xl" />
        <div className="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-br from-accent/20 to-primary/20 rounded-full blur-2xl" />

        <div className="relative z-10">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-primary to-secondary flex items-center justify-center shadow-xl">
              <Flame className="w-7 h-7 text-white" />
            </div>
            <div>
              <h2 className="text-2xl font-bold text-foreground">Racha de Ahorro</h2>
              <p className="text-sm text-foreground font-medium">Mantén tu disciplina financiera</p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4 mb-6">
            <div className="p-5 rounded-2xl bg-gradient-to-br from-primary to-primary-dark text-white">
              <div className="flex items-center gap-2 mb-3">
                <Flame className="w-6 h-6" />
                <span className="text-sm font-bold opacity-90">Racha Actual</span>
              </div>
              <p className="text-4xl font-bold mb-1">{currentStreak}</p>
              <p className="text-sm opacity-80">días seguidos</p>
            </div>

            <div className="p-5 rounded-2xl bg-gradient-to-br from-accent to-secondary text-white">
              <div className="flex items-center gap-2 mb-3">
                <Trophy className="w-6 h-6" />
                <span className="text-sm font-bold opacity-90">Récord</span>
              </div>
              <p className="text-4xl font-bold mb-1">{bestStreak}</p>
              <p className="text-sm opacity-80">días máximo</p>
            </div>
          </div>

          <div className="mb-6 p-4 rounded-2xl bg-white/50 dark:bg-black/20 border-2 border-dashed border-primary/30">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <Target className="w-5 h-5 text-primary" />
                <span className="text-sm font-bold text-foreground">Próximo Hito</span>
              </div>
              <span className="text-2xl font-bold text-primary">{nextMilestone} días</span>
            </div>
            <div className="w-full bg-border rounded-full h-3 overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-primary to-secondary transition-all duration-500 rounded-full"
                style={{ width: `${(currentStreak / nextMilestone) * 100}%` }}
              />
            </div>
            <p className="text-xs text-foreground mt-2 font-medium">
              Faltan {daysToMilestone} día{daysToMilestone !== 1 ? "s" : ""} para tu siguiente logro
            </p>
          </div>

          <div className="mb-6 p-5 rounded-2xl bg-gradient-to-r from-primary/10 to-accent/10 border-2 border-primary/30">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Calendar className="w-6 h-6 text-primary" />
                <span className="font-bold text-xl text-foreground">Metas Diarias</span>
              </div>
              <Button
                size="icon"
                onClick={() => setShowAddGoal(true)}
                className="rounded-xl bg-gradient-to-r from-primary to-secondary text-white hover:scale-105 transition-transform"
                title="Agregar nueva meta diaria"
              >
                <Plus className="w-5 h-5" />
              </Button>
            </div>

            {dailyGoals.length === 0 ? (
              <p className="text-sm text-foreground text-center py-4">
                No tienes metas diarias. ¡Agrega una para empezar!
              </p>
            ) : (
              <div className="space-y-3">
                {dailyGoals.map((goal) => (
                  <div
                    key={goal.id}
                    className={`p-4 rounded-xl border-2 transition-all ${
                      goal.completed
                        ? "bg-primary/10 border-primary/40"
                        : "bg-card border-primary/20 hover:border-primary/40"
                    }`}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex items-start gap-3 flex-1">
                        <button
                          onClick={() => handleToggleDailyGoal(goal.id)}
                          className={`w-6 h-6 rounded-full border-2 flex items-center justify-center transition-all flex-shrink-0 ${
                            goal.completed ? "bg-primary border-primary" : "border-primary/40 hover:border-primary"
                          }`}
                        >
                          {goal.completed && <span className="text-white text-sm font-bold">✓</span>}
                        </button>
                        <div className="flex-1">
                          <p className={`font-bold text-foreground ${goal.completed ? "line-through opacity-60" : ""}`}>
                            {goal.description}
                          </p>
                          <p className="text-sm text-foreground">Meta: ${goal.amount.toFixed(2)}</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2 flex-shrink-0">
                        <Target className="w-5 h-5 text-primary" />
                        <Button
                          size="icon"
                          variant="ghost"
                          onClick={() => handleDeleteDailyGoal(goal.id)}
                          className="w-8 h-8 rounded-lg hover:bg-destructive/10 hover:text-destructive"
                          title="Eliminar meta"
                        >
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Meta principal de ahorro */}
          <div className="p-5 rounded-2xl bg-gradient-to-r from-secondary/20 to-accent/20 border-2 border-secondary/30 mb-4">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <Award className="w-6 h-6 text-secondary" />
                <span className="font-bold text-2xl text-foreground">Meta de Ahorro Principal</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-lg font-bold text-secondary">{progress.toFixed(0)}%</span>
                <Button
                  variant="outline"
                  size="icon"
                  onClick={() => setIsEditingGoal(!isEditingGoal)}
                  className="rounded-lg h-8 w-8"
                  title="Editar meta"
                >
                  <Edit className="w-4 h-4" />
                </Button>
              </div>
            </div>

            {isEditingGoal && (
              <div className="mb-4 space-y-2">
                <Label htmlFor="new-goal" className="text-sm font-bold text-foreground">
                  Nueva Meta de Ahorro
                </Label>
                <div className="flex gap-2">
                  <div className="relative flex-1">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-foreground font-bold">$</span>
                    <Input
                      id="new-goal"
                      type="number"
                      step="0.01"
                      value={newGoal}
                      onChange={(e) => setNewGoal(e.target.value)}
                      placeholder="Ej: 10000"
                      className="pl-7 rounded-xl"
                    />
                  </div>
                  <Button onClick={handleSetGoal} className="rounded-xl font-bold">
                    Guardar
                  </Button>
                </div>
              </div>
            )}

            <div className="w-full bg-border rounded-full h-4 overflow-hidden mb-3">
              <div
                className="h-full bg-gradient-to-r from-secondary to-accent transition-all duration-500 rounded-full relative overflow-hidden"
                style={{ width: `${progress}%` }}
              >
                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent animate-shimmer" />
              </div>
            </div>

            <div className="flex justify-between text-sm mb-4">
              <span className="font-bold text-foreground text-2xl">${currentSavings.toLocaleString("es-MX")}</span>
              <span className="font-bold text-foreground text-3xl">Meta: ${savingsGoal.toLocaleString("es-MX")}</span>
            </div>

            {currentSavings < savingsGoal && (
              <Button
                onClick={handleCompleteGoal}
                className="w-full rounded-xl py-6 font-bold bg-gradient-to-r from-secondary to-accent text-white hover:scale-[1.02] transition-transform"
              >
                <Award className="w-5 h-5 mr-2" />
                ¡Completar Meta de Ahorro!
              </Button>
            )}
          </div>

          {aiRecommendation && (
            <div className="p-4 rounded-xl bg-gradient-to-r from-accent/10 to-primary/10 border-l-4 border-accent">
              <p className="text-sm font-bold text-foreground mb-1">💡 Recomendación de IA:</p>
              <p className="text-sm text-foreground">{aiRecommendation}</p>
            </div>
          )}

          <div className="mt-5 p-4 rounded-xl bg-gradient-to-r from-primary/10 to-accent/10 border-l-4 border-primary">
            <p className="text-sm font-bold text-foreground">
              {currentStreak >= 7
                ? "¡Increíble! Llevas una semana completa ahorrando. Sigue así!"
                : `¡Solo ${7 - currentStreak} día${7 - currentStreak !== 1 ? "s" : ""} más para completar tu primera semana!`}
            </p>
          </div>
        </div>
      </Card>

      {/* Modal para agregar meta diaria */}
      {showAddGoal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm animate-in fade-in duration-300">
          <div className="bg-card p-6 rounded-3xl shadow-2xl max-w-md mx-4 w-full animate-in zoom-in duration-300 border-2 border-primary/20">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center">
                <Target className="w-6 h-6 text-white" />
              </div>
              <h3 className="text-2xl font-bold text-foreground">Nueva Meta Diaria</h3>
            </div>

            <div className="space-y-4 mb-6">
              <div>
                <Label htmlFor="goal-desc" className="text-sm font-bold text-foreground mb-2 block">
                  Descripción
                </Label>
                <Input
                  id="goal-desc"
                  type="text"
                  value={newDailyGoal}
                  onChange={(e) => setNewDailyGoal(e.target.value)}
                  placeholder="Ej: No comprar café afuera"
                  className="rounded-xl"
                />
              </div>

              <div>
                <Label htmlFor="goal-amount" className="text-sm font-bold text-foreground mb-2 block">
                  Meta de ahorro ($)
                </Label>
                <Input
                  id="goal-amount"
                  type="number"
                  step="0.01"
                  value={newDailyAmount}
                  onChange={(e) => setNewDailyAmount(e.target.value)}
                  placeholder="Ej: 5.00"
                  className="rounded-xl"
                />
              </div>
            </div>

            <div className="flex gap-3">
              <Button
                variant="outline"
                onClick={() => {
                  setShowAddGoal(false)
                  setNewDailyGoal("")
                  setNewDailyAmount("")
                }}
                className="flex-1 rounded-xl py-6 font-bold"
              >
                Cancelar
              </Button>
              <Button
                onClick={handleAddDailyGoal}
                className="flex-1 rounded-xl py-6 font-bold bg-gradient-to-r from-primary to-secondary text-white hover:scale-[1.02] transition-transform"
              >
                <Plus className="w-5 h-5 mr-2" />
                Agregar
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Celebration modal */}
      {showCelebration && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm animate-in fade-in duration-300">
          <div className="bg-card p-8 rounded-3xl shadow-2xl max-w-md mx-4 text-center animate-in zoom-in duration-500">
            <div className="w-24 h-24 mx-auto mb-6 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center animate-bounce">
              <PartyPopper className="w-12 h-12 text-white" />
            </div>

            <h2 className="text-3xl font-bold mb-4 bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
              ¡Felicidades! 🎉
            </h2>

            <p className="text-lg mb-2 font-bold text-foreground">¡Has alcanzado tu meta de ahorro!</p>
            <p className="text-foreground mb-6">
              Ahorraste ${savingsGoal.toLocaleString("es-MX")} y aumentaste tu racha a {currentStreak} días
            </p>

            <div className="space-y-3 text-sm bg-gradient-to-r from-primary/10 to-secondary/10 p-4 rounded-2xl">
              <p className="font-bold text-foreground">💪 ¡Eres increíble!</p>
              <p className="text-foreground">Sigue así y alcanzarás todas tus metas financieras</p>
            </div>

            <Button
              onClick={() => setShowCelebration(false)}
              className="mt-6 w-full rounded-xl py-6 font-bold bg-gradient-to-r from-primary to-secondary text-white"
            >
              ¡Continuar Ahorrando!
            </Button>
          </div>
        </div>
      )}
    </>
  )
}
