"use client"

import { Card } from "@/components/ui/card"
import { ShoppingBag, Coffee, Car, Zap, TrendingUp } from "lucide-react"

const transactions = [
  { id: 1, name: "Supermercado", amount: -450.0, category: "Compras", icon: ShoppingBag, date: "Hoy" },
  { id: 2, name: "Café Starbucks", amount: -85.5, category: "Restaurantes", icon: Coffee, date: "Hoy" },
  { id: 3, name: "Gasolina", amount: -600.0, category: "Transporte", icon: Car, date: "Ayer" },
  { id: 4, name: "Salario", amount: 15000.0, category: "Ingreso", icon: TrendingUp, date: "2 días" },
  { id: 5, name: "Luz CFE", amount: -320.0, category: "Servicios", icon: Zap, date: "3 días" },
]

export function RecentTransactions() {
  return (
    <Card className="p-6">
      <h2 className="text-xl font-bold mb-6">Transacciones Recientes</h2>
      <div className="space-y-4">
        {transactions.map((transaction) => {
          const Icon = transaction.icon
          const isIncome = transaction.amount > 0

          return (
            <div key={transaction.id} className="flex items-center gap-4">
              <div
                className={`w-12 h-12 rounded-2xl flex items-center justify-center ${
                  isIncome ? "bg-primary/10" : "bg-secondary/10"
                }`}
              >
                <Icon className={`w-5 h-5 ${isIncome ? "text-primary" : "text-secondary"}`} />
              </div>

              <div className="flex-1 min-w-0">
                <p className="font-semibold truncate">{transaction.name}</p>
                <p className="text-sm text-muted">
                  {transaction.category} • {transaction.date}
                </p>
              </div>

              <div className="text-right">
                <p className={`font-bold ${isIncome ? "text-primary" : "text-foreground"}`}>
                  {isIncome ? "+" : ""}
                  {transaction.amount < 0 ? "-" : ""}${Math.abs(transaction.amount).toFixed(2)}
                </p>
              </div>
            </div>
          )
        })}
      </div>
    </Card>
  )
}
