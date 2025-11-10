"use client"

import type React from "react"

import { useState, useRef } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Plus,
  Wallet,
  UtensilsCrossed,
  Car,
  Tv,
  ShoppingBag,
  Wrench,
  Heart,
  GraduationCap,
  MoreHorizontal,
  Camera,
  X,
  MapPin,
  CalendarIcon,
} from "lucide-react"

interface AddExpenseFormProps {
  onAddExpense: (expense: {
    category: string
    amount: number
    description: string
    date: Date
    photoUrl?: string
    location?: string
    amountSaved?: number
  }) => void
}

const categoryIcons: Record<string, React.ReactNode> = {
  Restaurantes: <UtensilsCrossed className="w-5 h-5" />,
  Transporte: <Car className="w-5 h-5" />,
  Entretenimiento: <Tv className="w-5 h-5" />,
  Compras: <ShoppingBag className="w-5 h-5" />,
  Servicios: <Wrench className="w-5 h-5" />,
  Salud: <Heart className="w-5 h-5" />,
  Educación: <GraduationCap className="w-5 h-5" />,
  Otros: <MoreHorizontal className="w-5 h-5" />,
}

export function AddExpenseForm({ onAddExpense }: AddExpenseFormProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [category, setCategory] = useState("")
  const [amount, setAmount] = useState("")
  const [description, setDescription] = useState("")
  const [expenseDate, setExpenseDate] = useState(new Date().toISOString().slice(0, 16))
  const [photoUrl, setPhotoUrl] = useState<string>("")
  const [location, setLocation] = useState<string>("")
  const [isLoadingLocation, setIsLoadingLocation] = useState(false)
  const [showSavingsOption, setShowSavingsOption] = useState(false)
  const [amountSaved, setAmountSaved] = useState("")
  const fileInputRef = useRef<HTMLInputElement>(null)

  const categories = [
    "Restaurantes",
    "Transporte",
    "Entretenimiento",
    "Compras",
    "Servicios",
    "Salud",
    "Educación",
    "Otros",
  ]

  const getLocation = () => {
    setIsLoadingLocation(true)
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const lat = position.coords.latitude
          const lon = position.coords.longitude
          setLocation(`${lat.toFixed(6)}, ${lon.toFixed(6)}`)
          setIsLoadingLocation(false)
        },
        (error) => {
          console.error("Error obteniendo ubicación:", error)
          setLocation("Ubicación no disponible")
          setIsLoadingLocation(false)
        },
      )
    } else {
      setLocation("GPS no disponible")
      setIsLoadingLocation(false)
    }
  }

  const handlePhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      const reader = new FileReader()
      reader.onloadend = () => {
        setPhotoUrl(reader.result as string)
      }
      reader.readAsDataURL(file)
    }
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (category && amount && description) {
      onAddExpense({
        category,
        amount: Number.parseFloat(amount),
        description,
        date: new Date(expenseDate),
        photoUrl: photoUrl || undefined,
        location: location || undefined,
        amountSaved: amountSaved ? Number.parseFloat(amountSaved) : undefined,
      })
      // Reset form
      setCategory("")
      setAmount("")
      setDescription("")
      setExpenseDate(new Date().toISOString().slice(0, 16))
      setPhotoUrl("")
      setLocation("")
      setShowSavingsOption(false)
      setAmountSaved("")
      setIsOpen(false)

      setTimeout(() => {
        window.dispatchEvent(new CustomEvent("tutorial-action", { detail: { action: "add-expense" } }))
      }, 100)
    }
  }

  return (
    <Card className="p-6 bg-gradient-to-br from-secondary/10 to-primary/10 border-2 border-dashed border-primary/30">
      {!isOpen ? (
        <button
          id="add-expense-btn"
          onClick={() => {
            setIsOpen(true)
            setTimeout(() => {
              window.dispatchEvent(new CustomEvent("tutorial-action", { detail: { action: "open-add-expense" } }))
            }, 100)
          }}
          className="w-full flex items-center justify-center gap-3 py-4 rounded-2xl bg-gradient-to-r from-primary to-secondary text-white font-bold text-lg hover:scale-[1.02] transition-transform shadow-lg"
        >
          <Plus className="w-6 h-6" />
          Agregar Gasto
        </button>
      ) : (
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-accent to-secondary flex items-center justify-center">
              <Wallet className="w-6 h-6 text-white" />
            </div>
            <div>
              <h3 className="text-xl font-bold">Nuevo Gasto</h3>
              <p className="text-sm text-muted">Registra en qué gastaste</p>
            </div>
          </div>

          <div className="space-y-2">
            <Label className="text-sm font-bold">Categoría</Label>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              {categories.map((cat, index) => {
                const colors = [
                  "from-primary to-green-600",
                  "from-secondary to-blue-600",
                  "from-accent to-orange-600",
                  "from-purple-500 to-purple-700",
                  "from-pink-500 to-pink-700",
                  "from-teal-500 to-teal-700",
                  "from-indigo-500 to-indigo-700",
                  "from-red-500 to-red-700",
                ]
                const bgColor = colors[index % colors.length]

                return (
                  <button
                    key={cat}
                    id={cat === "Restaurantes" ? "category-restaurantes" : undefined}
                    data-selected={category === cat ? "true" : "false"}
                    type="button"
                    onClick={() => {
                      setCategory(cat)
                      if (cat === "Restaurantes") {
                        window.dispatchEvent(
                          new CustomEvent("tutorial-action", { detail: { action: "select-category" } }),
                        )
                      }
                    }}
                    className={`p-4 rounded-2xl border-2 flex flex-col items-center gap-2 transition-all ${
                      category === cat
                        ? "border-primary bg-primary/10 scale-105"
                        : "border-border hover:border-primary/50 hover:bg-primary/5"
                    }`}
                  >
                    <div
                      className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                        category === cat
                          ? `bg-gradient-to-br ${bgColor} text-white`
                          : "bg-muted/30 text-muted-foreground"
                      }`}
                    >
                      {categoryIcons[cat]}
                    </div>
                    <span className="text-xs font-bold text-center">{cat}</span>
                  </button>
                )
              })}
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="expense-amount-input" className="text-sm font-bold">
              Monto
            </Label>
            <div className="relative">
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-muted font-bold">$</span>
              <Input
                id="expense-amount-input"
                type="number"
                step="0.01"
                value={amount}
                onChange={(e) => {
                  setAmount(e.target.value)
                  if (e.target.value) {
                    window.dispatchEvent(
                      new CustomEvent("tutorial-action", { detail: { action: "enter-expense-amount" } }),
                    )
                  }
                }}
                placeholder="0.00"
                className="pl-8 py-3 rounded-xl border-2 text-lg"
                required
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="expense-description-input" className="text-sm font-bold">
              Descripción
            </Label>
            <Input
              id="expense-description-input"
              type="text"
              value={description}
              onChange={(e) => {
                setDescription(e.target.value)
                if (e.target.value.trim().length >= 3) {
                  window.dispatchEvent(new CustomEvent("tutorial-action", { detail: { action: "enter-description" } }))
                }
              }}
              placeholder="¿En qué gastaste?"
              className="py-3 rounded-xl border-2"
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="expenseDate" className="text-sm font-bold">
              Fecha y Hora
            </Label>
            <div className="relative">
              <CalendarIcon className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted" />
              <Input
                id="expenseDate"
                type="datetime-local"
                value={expenseDate}
                onChange={(e) => setExpenseDate(e.target.value)}
                className="pl-12 py-3 rounded-xl border-2"
                required
              />
            </div>
            <p className="text-xs text-muted-foreground">Puedes agregar gastos de cualquier fecha</p>
          </div>

          <div className="space-y-2">
            <Label className="text-sm font-bold">Ubicación (Opcional)</Label>
            <div className="flex gap-3">
              <Button
                type="button"
                variant="outline"
                onClick={getLocation}
                disabled={isLoadingLocation}
                className="flex-1 rounded-xl py-6 font-bold border-2 border-dashed bg-transparent"
              >
                <MapPin className="w-5 h-5 mr-2" />
                {isLoadingLocation ? "Obteniendo..." : location || "Agregar Ubicación"}
              </Button>
              {location && (
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => setLocation("")}
                  className="rounded-xl px-4 border-2"
                >
                  <X className="w-5 h-5" />
                </Button>
              )}
            </div>
            {location && !isLoadingLocation && <p className="text-xs text-muted">📍 {location}</p>}
          </div>

          <div className="space-y-2">
            <Label className="text-sm font-bold">Foto (Opcional)</Label>
            <div className="flex gap-3">
              <input ref={fileInputRef} type="file" accept="image/*" onChange={handlePhotoChange} className="hidden" />
              <Button
                type="button"
                variant="outline"
                onClick={() => fileInputRef.current?.click()}
                className="flex-1 rounded-xl py-6 font-bold border-2 border-dashed"
              >
                <Camera className="w-5 h-5 mr-2" />
                {photoUrl ? "Cambiar Foto" : "Agregar Evidencia"}
              </Button>
              {photoUrl && (
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => setPhotoUrl("")}
                  className="rounded-xl px-4 border-2"
                >
                  <X className="w-5 h-5" />
                </Button>
              )}
            </div>
            {photoUrl && (
              <div className="mt-3 rounded-2xl overflow-hidden border-2 border-border">
                <img
                  src={photoUrl || "/placeholder.svg"}
                  alt="Evidencia del gasto"
                  className="w-full h-48 object-cover"
                />
              </div>
            )}
          </div>

          <div className="space-y-2">
            <button
              type="button"
              onClick={() => setShowSavingsOption(!showSavingsOption)}
              className="w-full text-sm font-bold text-primary hover:text-primary/80 text-left py-2 px-2 rounded-lg hover:bg-primary/5 transition-colors"
            >
              {showSavingsOption ? "✓ ¿Ahorraste dinero?" : "+ ¿Ahorraste dinero?"}
            </button>
            {showSavingsOption && (
              <div className="p-4 rounded-xl bg-green-500/10 border-2 border-green-500/30 space-y-3">
                <p className="text-sm text-foreground font-medium">
                  ¡Muy bien! Registra cuánto ahorraste en este gasto
                </p>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-muted font-bold">$</span>
                  <Input
                    type="number"
                    step="0.01"
                    value={amountSaved}
                    onChange={(e) => setAmountSaved(e.target.value)}
                    placeholder="0.00"
                    className="pl-8 py-3 rounded-xl border-2 border-green-500/30"
                  />
                </div>
                {amountSaved && (
                  <p className="text-xs text-green-700 font-semibold bg-green-100/50 p-2 rounded-lg">
                    ✨ Agregarás ${Number(amountSaved).toFixed(2)} a tus ahorros totales
                  </p>
                )}
              </div>
            )}
          </div>

          <div className="flex gap-3 pt-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => {
                setIsOpen(false)
                setPhotoUrl("")
                setLocation("")
                setShowSavingsOption(false)
                setAmountSaved("")
              }}
              className="flex-1 rounded-xl py-6 font-bold"
            >
              Cancelar
            </Button>
            <Button
              id="save-expense-btn"
              type="submit"
              className="flex-1 rounded-xl py-6 font-bold bg-gradient-to-r from-primary to-secondary text-white hover:scale-[1.02] transition-transform"
            >
              Guardar Gasto
            </Button>
          </div>
        </form>
      )}
    </Card>
  )
}
