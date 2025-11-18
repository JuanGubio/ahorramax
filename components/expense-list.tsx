"use client"

import { useState } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import {
  ChevronDown,
  ChevronUp,
  UtensilsCrossed,
  Car,
  Tv,
  ShoppingBag,
  Wrench,
  Heart,
  GraduationCap,
  MoreHorizontal,
  Calendar,
  Clock,
  ImageIcon,
  MapPin,
  Trash2,
} from "lucide-react"

interface Expense {
  category: string
  amount: number
  description: string
  date: Date
  photoUrl?: string
  location?: string
}

interface ExpenseListProps {
  expenses: Expense[]
  onDeleteExpense?: (index: number) => void
}

const categoryIcons: Record<string, any> = {
  Restaurantes: UtensilsCrossed,
  Transporte: Car,
  Entretenimiento: Tv,
  Compras: ShoppingBag,
  Servicios: Wrench,
  Salud: Heart,
  Educación: GraduationCap,
  Otros: MoreHorizontal,
}

const categoryColors: Record<string, string> = {
  Restaurantes: "from-primary to-primary-dark",
  Transporte: "from-secondary to-accent",
  Entretenimiento: "from-accent to-secondary",
  Compras: "from-primary to-secondary",
  Servicios: "from-secondary to-primary",
  Salud: "from-accent to-primary",
  Educación: "from-primary to-accent",
  Otros: "from-secondary to-accent",
}

export function ExpenseList({ expenses, onDeleteExpense }: ExpenseListProps) {
  const [isExpanded, setIsExpanded] = useState(false)
  const [deleteIndex, setDeleteIndex] = useState<number | null>(null)

  const sortedExpenses = [...expenses].sort((a, b) => b.date.getTime() - a.date.getTime())

  const formatDate = (date: Date) => {
    const today = new Date()
    const yesterday = new Date(today)
    yesterday.setDate(yesterday.getDate() - 1)

    if (date.toDateString() === today.toDateString()) return "Hoy"
    if (date.toDateString() === yesterday.toDateString()) return "Ayer"

    return date.toLocaleDateString("es-MX", { day: "numeric", month: "short" })
  }

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString("es-MX", { hour: "2-digit", minute: "2-digit" })
  }

  const handleConfirmDelete = () => {
    if (deleteIndex !== null && onDeleteExpense) {
      onDeleteExpense(deleteIndex)
      setDeleteIndex(null)
    }
  }

  return (
    <Card className="p-6 bg-card border-2 border-border">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-xl font-bold">Mis Gastos</h2>
          <p className="text-sm text-muted">
            {expenses.length} {expenses.length === 1 ? "gasto registrado" : "gastos registrados"}
          </p>
        </div>
        <Button onClick={() => setIsExpanded(!isExpanded)} variant="outline" className="rounded-xl font-bold">
          {isExpanded ? (
            <>
              <ChevronUp className="w-5 h-5 mr-2" />
              Ocultar
            </>
          ) : (
            <>
              <ChevronDown className="w-5 h-5 mr-2" />
              Ver Todo
            </>
          )}
        </Button>
      </div>

      {isExpanded && (
        <div className="space-y-4">
          {sortedExpenses.map((expense, index) => {
            const Icon = categoryIcons[expense.category] || MoreHorizontal
            const colorClass = categoryColors[expense.category] || "from-primary to-secondary"

            return (
              <div
                key={index}
                className="p-4 rounded-2xl border-2 border-border hover:border-primary/50 transition-all space-y-3"
              >
                <div className="flex items-start gap-4">
                  <div
                    className={`w-12 h-12 rounded-2xl bg-gradient-to-br ${colorClass} flex items-center justify-center flex-shrink-0`}
                  >
                    <Icon className="w-6 h-6 text-white" />
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between gap-2 mb-2">
                      <div>
                        <p className="font-bold text-lg">{expense.description}</p>
                        <p className="text-sm text-muted">{expense.category}</p>
                      </div>
                      <p className="font-bold text-xl text-foreground whitespace-nowrap">
                        -${expense.amount.toFixed(2)}
                      </p>
                    </div>

                    <div className="flex flex-wrap gap-3 text-sm text-muted">
                      <div className="flex items-center gap-1">
                        <Calendar className="w-4 h-4" />
                        <span>{formatDate(expense.date)}</span>
                      </div>
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
                      {expense.photoUrl && (
                        <div className="flex items-center gap-1 text-primary">
                          <ImageIcon className="w-4 h-4" />
                          <span>Con foto</span>
                        </div>
                      )}
                    </div>
                  </div>

                  {onDeleteExpense && (
                    <Button
                      variant="outline"
                      size="icon"
                      onClick={() => setDeleteIndex(index)}
                      className="rounded-xl border-2 hover:bg-red-50 hover:border-red-500 hover:text-red-500"
                      title="Eliminar gasto"
                    >
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  )}
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

          {expenses.length === 0 && (
            <div className="text-center py-12">
              <div className="w-20 h-20 mx-auto mb-4 rounded-full bg-gradient-to-br from-primary/20 to-secondary/20 flex items-center justify-center">
                <ShoppingBag className="w-10 h-10 text-primary" />
              </div>
              <p className="text-lg font-bold mb-2">No hay gastos registrados</p>
              <p className="text-sm text-muted">Agrega tu primer gasto para empezar</p>
            </div>
          )}
        </div>
      )}

      {deleteIndex !== null && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm animate-in fade-in duration-300">
          <div className="bg-card p-6 rounded-3xl shadow-2xl max-w-md mx-4 text-center animate-in zoom-in duration-300">
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-gradient-to-br from-red-400 to-red-600 flex items-center justify-center">
              <Trash2 className="w-8 h-8 text-white" />
            </div>

            <h3 className="text-2xl font-bold mb-3">¿Eliminar este gasto?</h3>
            <p className="text-muted mb-6">
              Se eliminará el gasto de <span className="font-bold">{sortedExpenses[deleteIndex]?.description}</span> por{" "}
              <span className="font-bold">${sortedExpenses[deleteIndex]?.amount.toFixed(2)}</span>
            </p>

            <div className="flex gap-3">
              <Button
                variant="outline"
                onClick={() => setDeleteIndex(null)}
                className="flex-1 rounded-xl py-6 font-bold"
              >
                Cancelar
              </Button>
              <Button
                onClick={handleConfirmDelete}
                className="flex-1 rounded-xl py-6 font-bold bg-gradient-to-r from-red-500 to-red-600 text-white hover:scale-[1.02] transition-transform"
              >
                Sí, Eliminar
              </Button>
            </div>
          </div>
        </div>
      )}
    </Card>
  )
}
