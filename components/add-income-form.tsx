"use client"

import type React from "react"

import { useState } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Plus, DollarSign, Briefcase, TrendingUp, Gift, PiggyBank } from "lucide-react"

interface AddIncomeFormProps {
  onAddIncome: (income: { source: string; amount: number; description: string; date: Date }) => void
}

const incomeIcons: Record<string, any> = {
  Salario: Briefcase,
  Freelance: TrendingUp,
  Regalo: Gift,
  Ahorro: PiggyBank,
  Otros: DollarSign,
}

export function AddIncomeForm({ onAddIncome }: AddIncomeFormProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [source, setSource] = useState("")
  const [amount, setAmount] = useState("")
  const [description, setDescription] = useState("")

  const sources = ["Salario", "Freelance", "Regalo", "Ahorro", "Otros"]

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (source && amount && description) {
      onAddIncome({
        source,
        amount: Number.parseFloat(amount),
        description,
        date: new Date(),
      })

      window.dispatchEvent(
        new CustomEvent("tutorial-action", {
          detail: { action: "add-money" },
        }),
      )

      setSource("")
      setAmount("")
      setDescription("")
      setIsOpen(false)
    }
  }

  const handleAmountChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setAmount(e.target.value)
    if (e.target.value) {
      window.dispatchEvent(
        new CustomEvent("tutorial-action", {
          detail: { action: "enter-amount" },
        }),
      )
    }
  }

  return (
    <Card className="p-6 bg-gradient-to-br from-primary/10 to-accent/10 border-2 border-dashed border-primary/30">
      {!isOpen ? (
        <button
          id="balance-add-btn"
          onClick={() => {
            setIsOpen(true)
            window.dispatchEvent(
              new CustomEvent("tutorial-action", {
                detail: { action: "open-add-money" },
              }),
            )
          }}
          className="w-full flex items-center justify-center gap-3 py-4 rounded-2xl bg-gradient-to-r from-primary to-accent text-white font-bold text-lg hover:scale-[1.02] transition-transform"
        >
          <Plus className="w-6 h-6" />
          Agregar Ingreso
        </button>
      ) : (
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-primary to-accent flex items-center justify-center">
              <DollarSign className="w-6 h-6 text-white" />
            </div>
            <div>
              <h3 className="text-xl font-bold">Nuevo Ingreso</h3>
              <p className="text-sm text-muted">Registra tu dinero recibido</p>
            </div>
          </div>

          <div className="space-y-2">
            <Label className="text-sm font-bold">Fuente de Ingreso</Label>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {sources.map((src) => {
                const Icon = incomeIcons[src]
                return (
                  <button
                    key={src}
                    type="button"
                    onClick={() => setSource(src)}
                    className={`p-4 rounded-2xl border-2 flex flex-col items-center gap-2 transition-all ${
                      source === src
                        ? "border-primary bg-primary/10 scale-105"
                        : "border-border hover:border-primary/50 hover:bg-primary/5"
                    }`}
                  >
                    <div
                      className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                        source === src ? "bg-primary text-white" : "bg-primary/20 text-primary"
                      }`}
                    >
                      <Icon className="w-5 h-5" />
                    </div>
                    <span className="text-xs font-bold text-center">{src}</span>
                  </button>
                )
              })}
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="income-amount" className="text-sm font-bold">
              Monto
            </Label>
            <div className="relative">
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-muted font-bold">$</span>
              <Input
                id="add-money-input"
                type="number"
                step="0.01"
                value={amount}
                onChange={handleAmountChange}
                placeholder="0.00"
                className="pl-8 py-3 rounded-xl border-2 text-lg"
                required
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="income-description" className="text-sm font-bold">
              Descripción
            </Label>
            <Input
              id="income-description"
              type="text"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="¿De dónde viene este ingreso?"
              className="py-3 rounded-xl border-2"
              required
            />
          </div>

          <div className="flex gap-3 pt-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => setIsOpen(false)}
              className="flex-1 rounded-xl py-6 font-bold"
            >
              Cancelar
            </Button>
            <Button
              id="add-money-submit"
              type="submit"
              className="flex-1 rounded-xl py-6 font-bold bg-gradient-to-r from-primary to-accent text-white hover:scale-[1.02] transition-transform"
            >
              Guardar Ingreso
            </Button>
          </div>
        </form>
      )}
    </Card>
  )
}
