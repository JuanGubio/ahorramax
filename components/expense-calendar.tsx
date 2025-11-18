"use client"

import type React from "react"

import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import {
  Calendar,
  ChevronLeft,
  ChevronRight,
  UtensilsCrossed,
  Car,
  Tv,
  ShoppingBag,
  Wrench,
  Heart,
  GraduationCap,
  MoreHorizontal,
  X,
  MapPin,
  Clock,
} from "lucide-react"
import { useState } from "react"

interface Expense {
  category: string
  amount: number
  description: string
  date: Date
  location?: string
  photoUrl?: string
}

interface ExpenseCalendarProps {
  expenses: Expense[]
  budget: number
}

const categoryIcons: Record<string, React.ReactNode> = {
  Restaurantes: <UtensilsCrossed className="w-3 h-3" />,
  Transporte: <Car className="w-3 h-3" />,
  Entretenimiento: <Tv className="w-3 h-3" />,
  Compras: <ShoppingBag className="w-3 h-3" />,
  Servicios: <Wrench className="w-3 h-3" />,
  Salud: <Heart className="w-3 h-3" />,
  Educación: <GraduationCap className="w-3 h-3" />,
  Otros: <MoreHorizontal className="w-3 h-3" />,
}

const categoryColors: Record<string, string> = {
  Restaurantes: "bg-primary text-white",
  Transporte: "bg-secondary text-white",
  Entretenimiento: "bg-accent text-white",
  Compras: "bg-yellow-500 text-white",
  Servicios: "bg-purple-500 text-white",
  Salud: "bg-red-500 text-white",
  Educación: "bg-blue-500 text-white",
  Otros: "bg-gray-500 text-white",
}

const categoryFullColors: Record<string, string> = {
  Restaurantes: "from-primary to-primary-dark",
  Transporte: "from-secondary to-accent",
  Entretenimiento: "from-accent to-secondary",
  Compras: "from-yellow-400 to-yellow-600",
  Servicios: "from-purple-400 to-purple-600",
  Salud: "from-red-400 to-red-600",
  Educación: "from-blue-400 to-blue-600",
  Otros: "from-gray-400 to-gray-600",
}

export function ExpenseCalendar({ expenses, budget }: ExpenseCalendarProps) {
  const [currentDate, setCurrentDate] = useState(new Date())
  const [selectedDay, setSelectedDay] = useState<number | null>(null)
  const [selectedExpenses, setSelectedExpenses] = useState<Expense[]>([])

  const monthNames = [
    "Enero",
    "Febrero",
    "Marzo",
    "Abril",
    "Mayo",
    "Junio",
    "Julio",
    "Agosto",
    "Septiembre",
    "Octubre",
    "Noviembre",
    "Diciembre",
  ]
  const dayNames = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]

  const year = currentDate.getFullYear()
  const month = currentDate.getMonth()

  const firstDay = new Date(year, month, 1).getDay()
  const daysInMonth = new Date(year, month + 1, 0).getDate()

  const days = []
  for (let i = 0; i < firstDay; i++) {
    days.push(null)
  }
  for (let i = 1; i <= daysInMonth; i++) {
    days.push(i)
  }

  const expensesByDay: Record<number, Expense[]> = {}
  expenses.forEach((expense) => {
    const expenseDate = new Date(expense.date)
    if (expenseDate.getMonth() === month && expenseDate.getFullYear() === year) {
      const day = expenseDate.getDate()
      if (!expensesByDay[day]) {
        expensesByDay[day] = []
      }
      expensesByDay[day].push(expense)
    }
  })

  const handleDayClick = (day: number | null) => {
    if (day && expensesByDay[day]) {
      setSelectedDay(day)
      setSelectedExpenses(expensesByDay[day])
    }
  }

  const changeMonth = (delta: number) => {
    const newDate = new Date(year, month + delta, 1)
    setCurrentDate(newDate)
    setSelectedDay(null)
    setSelectedExpenses([])
  }

  const today = new Date().getDate()
  const isCurrentMonth = new Date().getMonth() === month && new Date().getFullYear() === year

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString("es-MX", { hour: "2-digit", minute: "2-digit" })
  }

  const totalExpensesThisMonth = expenses.reduce((sum, exp) => {
    const expenseDate = new Date(exp.date)
    return expenseDate.getMonth() === month && expenseDate.getFullYear() === year ? sum + exp.amount : sum
  }, 0)

  const remainingBudget = budget - totalExpensesThisMonth

  return (
    <>
      <Card className="p-6 bg-gradient-to-br from-secondary/5 to-accent/5">
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-accent to-secondary flex items-center justify-center shadow-lg">
              <Calendar className="w-6 h-6 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-foreground">Calendario de Gastos</h2>
              <p className="text-sm text-foreground font-medium">Tus gastos por día</p>
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between mb-6 p-3 rounded-xl bg-primary/5">
          <button onClick={() => changeMonth(-1)} className="p-2 rounded-lg hover:bg-primary/10 transition-colors">
            <ChevronLeft className="w-5 h-5 text-foreground" />
          </button>
          <span className="text-lg font-bold text-foreground">
            {monthNames[month]} {year}
          </span>
          <button onClick={() => changeMonth(1)} className="p-2 rounded-lg hover:bg-primary/10 transition-colors">
            <ChevronRight className="w-5 h-5 text-foreground" />
          </button>
        </div>

        <div className="grid grid-cols-7 gap-2 mb-3">
          {dayNames.map((day) => (
            <div key={day} className="text-center text-xs font-bold text-foreground py-2">
              {day}
            </div>
          ))}
        </div>

        <div className="grid grid-cols-7 gap-2">
          {days.map((day, idx) => {
            const hasExpenses = day && expensesByDay[day]
            const isToday = isCurrentMonth && day === today

            return (
              <button
                key={idx}
                onClick={() => handleDayClick(day)}
                disabled={!hasExpenses}
                className={`aspect-square p-1 rounded-xl relative transition-all ${
                  day
                    ? isToday
                      ? "bg-gradient-to-br from-primary to-secondary text-white font-bold ring-2 ring-primary ring-offset-2"
                      : hasExpenses
                        ? "bg-accent/10 hover:bg-accent/20 cursor-pointer border-2 border-accent/30 hover:scale-105"
                        : "bg-background hover:bg-muted/50 border border-border"
                    : ""
                }`}
              >
                {day && (
                  <>
                    <span className={`text-sm font-bold ${isToday ? "text-white" : "text-foreground"}`}>{day}</span>
                    {hasExpenses && (
                      <div className="absolute bottom-1 left-1 right-1 flex gap-0.5 flex-wrap justify-center">
                        {expensesByDay[day].slice(0, 3).map((expense, expIdx) => (
                          <div
                            key={expIdx}
                            className={`w-5 h-5 rounded-md flex items-center justify-center ${categoryColors[expense.category]} shadow-sm`}
                          >
                            {categoryIcons[expense.category]}
                          </div>
                        ))}
                      </div>
                    )}
                  </>
                )}
              </button>
            )
          })}
        </div>

        <div className="mt-6 p-4 rounded-xl bg-primary/5">
          <p className="text-xs font-bold text-foreground mb-3">Categorías:</p>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
            {Object.entries(categoryIcons).map(([category, icon]) => (
              <div key={category} className="flex items-center gap-2">
                <div className={`w-6 h-6 rounded-lg flex items-center justify-center ${categoryColors[category]}`}>
                  {icon}
                </div>
                <span className="text-xs font-medium text-foreground">{category}</span>
              </div>
            ))}
          </div>
        </div>

        {expenses.length === 0 && (
          <div className="mt-4 p-4 rounded-xl bg-muted/20 text-center">
            <p className="text-sm font-bold text-foreground">0 gastos registrados</p>
            <p className="text-xs text-foreground mt-1">Agrega tu primer gasto para verlo en el calendario</p>
          </div>
        )}

        {expenses.length > 0 && (
          <div className="mt-4 p-4 rounded-xl bg-gradient-to-r from-primary/10 to-accent/10">
            <p className="text-sm font-bold text-foreground mb-1">💰 Por gastar este mes</p>
            <p className="text-xs text-foreground">
              Planifica tus gastos futuros y agrégalos con fechas futuras para no olvidarlos
            </p>
            <p className="text-sm text-foreground mt-1">Presupuesto restante: ${remainingBudget.toFixed(2)}</p>
          </div>
        )}
      </Card>

      {selectedDay && selectedExpenses.length > 0 && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm animate-in fade-in duration-300">
          <div className="bg-card p-6 rounded-3xl shadow-2xl max-w-2xl w-full mx-4 max-h-[80vh] overflow-y-auto animate-in zoom-in duration-300">
            <div className="flex items-center justify-between mb-6">
              <div>
                <h3 className="text-2xl font-bold text-foreground">
                  Gastos del {selectedDay} de {monthNames[month]}
                </h3>
                <p className="text-sm text-foreground">
                  {selectedExpenses.length} {selectedExpenses.length === 1 ? "gasto" : "gastos"} registrado
                  {selectedExpenses.length === 1 ? "" : "s"}
                </p>
              </div>
              <Button
                variant="outline"
                size="icon"
                onClick={() => {
                  setSelectedDay(null)
                  setSelectedExpenses([])
                }}
                className="rounded-xl"
              >
                <X className="w-5 h-5" />
              </Button>
            </div>

            <div className="space-y-4">
              {selectedExpenses.map((expense, idx) => {
                const Icon =
                  (expense.category === "Restaurantes" && UtensilsCrossed) ||
                  (expense.category === "Transporte" && Car) ||
                  (expense.category === "Entretenimiento" && Tv) ||
                  (expense.category === "Compras" && ShoppingBag) ||
                  (expense.category === "Servicios" && Wrench) ||
                  (expense.category === "Salud" && Heart) ||
                  (expense.category === "Educación" && GraduationCap) ||
                  MoreHorizontal

                const colorClass = categoryFullColors[expense.category] || "from-primary to-secondary"

                return (
                  <div key={idx} className="p-4 rounded-2xl border-2 border-border space-y-3">
                    <div className="flex items-start gap-4">
                      <div
                        className={`w-12 h-12 rounded-2xl bg-gradient-to-br ${colorClass} flex items-center justify-center flex-shrink-0`}
                      >
                        <Icon className="w-6 h-6 text-white" />
                      </div>

                      <div className="flex-1">
                        <div className="flex items-start justify-between gap-2 mb-2">
                          <div>
                            <p className="font-bold text-lg text-foreground">{expense.description}</p>
                            <p className="text-sm text-foreground">{expense.category}</p>
                          </div>
                          <p className="font-bold text-xl text-foreground whitespace-nowrap">
                            -${expense.amount.toFixed(2)}
                          </p>
                        </div>

                        <div className="flex flex-wrap gap-3 text-sm text-foreground">
                          <div className="flex items-center gap-1">
                            <Clock className="w-4 h-4" />
                            <span>{formatTime(expense.date)}</span>
                          </div>
                          {expense.location && (
                            <div className="flex items-center gap-1 text-primary">
                              <MapPin className="w-4 h-4" />
                              <span className="truncate max-w-[200px]">{expense.location}</span>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>

                    {expense.photoUrl && (
                      <div className="rounded-xl overflow-hidden border-2 border-border">
                        <img
                          src={expense.photoUrl || "/placeholder.svg"}
                          alt={`Evidencia de ${expense.description}`}
                          className="w-full h-48 object-cover"
                        />
                      </div>
                    )}
                  </div>
                )
              })}

              <div className="pt-2">
                <div className="p-4 rounded-xl bg-gradient-to-r from-primary/10 to-accent/10">
                  <p className="font-bold text-lg mb-1 text-foreground">
                    Total del día: ${selectedExpenses.reduce((sum, exp) => sum + exp.amount, 0).toFixed(2)}
                  </p>
                  <p className="text-sm text-foreground">
                    Promedio por gasto: $
                    {(selectedExpenses.reduce((sum, exp) => sum + exp.amount, 0) / selectedExpenses.length).toFixed(2)}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
