"use client"

import type React from "react"

import { Card } from "@/components/ui/card"
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from "recharts"
import {
  TrendingUp,
  PieChartIcon,
  UtensilsCrossed,
  Car,
  Tv,
  ShoppingBag,
  Wrench,
  Heart,
  GraduationCap,
  MoreHorizontal,
} from "lucide-react"
import { useState } from "react"

interface ExpenseChartProps {
  expenses: Array<{ category: string; amount: number; description: string }>
}

const COLORS = [
  "hsl(var(--color-primary))",
  "hsl(var(--color-secondary))",
  "hsl(var(--color-accent))",
  "#10b981",
  "#f59e0b",
  "#ef4444",
  "#8b5cf6",
  "#ec4899",
]

const categoryIcons: Record<string, React.ReactNode> = {
  Restaurantes: <UtensilsCrossed className="w-4 h-4" />,
  Transporte: <Car className="w-4 h-4" />,
  Entretenimiento: <Tv className="w-4 h-4" />,
  Compras: <ShoppingBag className="w-4 h-4" />,
  Servicios: <Wrench className="w-4 h-4" />,
  Salud: <Heart className="w-4 h-4" />,
  Educación: <GraduationCap className="w-4 h-4" />,
  Otros: <MoreHorizontal className="w-4 h-4" />,
}

export function ExpenseChart({ expenses }: ExpenseChartProps) {
  const [chartType, setChartType] = useState<"bar" | "pie">("pie")

  const expensesByCategory = expenses.reduce(
    (acc, expense) => {
      const existing = acc.find((e) => e.name === expense.category)
      if (existing) {
        existing.value += expense.amount
      } else {
        acc.push({ name: expense.category, value: expense.amount })
      }
      return acc
    },
    [] as Array<{ name: string; value: number }>,
  )

  const totalExpenses = expensesByCategory.reduce((sum, cat) => sum + cat.value, 0)

  // Datos para gráfico de barras (últimos 6 meses simulados)
  const monthlyData = [
    { name: "Ene", gastos: 4200, ahorros: 800 },
    { name: "Feb", gastos: 3800, ahorros: 1200 },
    { name: "Mar", gastos: 4500, ahorros: 500 },
    { name: "Abr", gastos: 4100, ahorros: 900 },
    { name: "May", gastos: 3900, ahorros: 1100 },
    { name: "Jun", gastos: totalExpenses, ahorros: 650 },
  ]

  return (
    <Card className="p-6 bg-gradient-to-br from-primary/5 to-secondary/5">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-secondary to-accent flex items-center justify-center shadow-lg">
            <TrendingUp className="w-6 h-6 text-white" />
          </div>
          <div>
            <h2 className="text-xl font-bold text-foreground">Estadísticas</h2>
            <p className="text-sm text-foreground font-medium">Tus gastos del mes</p>
          </div>
        </div>

        <button
          onClick={() => setChartType(chartType === "bar" ? "pie" : "bar")}
          className="p-2 rounded-xl bg-primary/10 hover:bg-primary/20 transition-colors"
        >
          <PieChartIcon className="w-5 h-5 text-primary" />
        </button>
      </div>

      <div className="mb-6 p-5 rounded-2xl bg-gradient-to-r from-accent via-secondary to-primary text-white shadow-lg relative overflow-hidden">
        <div className="absolute top-0 right-0 w-24 h-24 bg-white/10 rounded-full blur-2xl" />
        <div className="relative z-10">
          <p className="text-sm font-bold mb-1 opacity-90">Total Gastado Este Mes</p>
          <p className="text-4xl font-bold">${totalExpenses.toLocaleString("es-MX", { minimumFractionDigits: 2 })}</p>
        </div>
      </div>

      {expenses.length === 0 && (
        <div className="text-center py-12">
          <p className="text-foreground font-medium">0 gastos registrados</p>
          <p className="text-sm text-foreground mt-2">Agrega tu primer gasto para ver estadísticas</p>
        </div>
      )}

      {chartType === "pie" && expenses.length > 0 ? (
        <>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={expensesByCategory}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                outerRadius={100}
                fill="#8884d8"
                dataKey="value"
              >
                {expensesByCategory.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip
                contentStyle={{
                  backgroundColor: "hsl(var(--card))",
                  border: "2px solid hsl(var(--primary))",
                  borderRadius: "1rem",
                  fontWeight: "bold",
                }}
                formatter={(value: number) => `$${value.toLocaleString("es-MX")}`}
              />
            </PieChart>
          </ResponsiveContainer>

          <div className="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-3">
            {expensesByCategory.map((cat, index) => {
              const percentage = ((cat.value / totalExpenses) * 100).toFixed(1)
              return (
                <div
                  key={cat.name}
                  className="p-4 rounded-xl bg-gradient-to-br from-background to-muted/20 border-2 border-border hover:border-primary/30 transition-all"
                >
                  <div className="flex items-center gap-3 mb-2">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center text-white shadow-md"
                      style={{ backgroundColor: COLORS[index % COLORS.length] }}
                    >
                      {categoryIcons[cat.name]}
                    </div>
                    <div className="flex-1">
                      <p className="text-sm font-bold">{cat.name}</p>
                      <p className="text-xs text-muted">{percentage}% del total</p>
                    </div>
                  </div>
                  <p className="text-2xl font-bold text-foreground">${cat.value.toLocaleString("es-MX")}</p>
                </div>
              )
            })}
          </div>
        </>
      ) : chartType === "bar" && expenses.length > 0 ? (
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={monthlyData}>
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
            <XAxis dataKey="name" stroke="hsl(var(--muted))" style={{ fontWeight: "bold" }} />
            <YAxis stroke="hsl(var(--muted))" />
            <Tooltip
              contentStyle={{
                backgroundColor: "hsl(var(--card))",
                border: "2px solid hsl(var(--primary))",
                borderRadius: "1rem",
                fontWeight: "bold",
              }}
              formatter={(value: number) => `$${value.toLocaleString("es-MX")}`}
            />
            <Bar dataKey="gastos" fill="hsl(var(--color-secondary))" radius={[12, 12, 0, 0]} />
            <Bar dataKey="ahorros" fill="hsl(var(--color-primary))" radius={[12, 12, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      ) : null}
    </Card>
  )
}
