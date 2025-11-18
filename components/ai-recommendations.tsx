"use client"

import { useState, useEffect } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Sparkles, RefreshCw, X } from "lucide-react"

interface Recommendation {
  id: string
  title: string
  description: string
  potentialSavings: number
  category: string
  location?: string
}

interface AIRecommendationsProps {
  expenses: Array<{ category: string; amount: number; description: string }>
  onAcceptSavings: (savingsAmount: number) => void
}

export function AIRecommendations({ expenses, onAcceptSavings }: AIRecommendationsProps) {
  const [recommendations, setRecommendations] = useState<Recommendation[]>([])
  const [loading, setLoading] = useState(false)
  const [acceptedRecommendations, setAcceptedRecommendations] = useState<Set<string>>(new Set())
  const [isVisible, setIsVisible] = useState(true)

  const fetchRecommendations = async () => {
    setLoading(true)
    try {
      const expensesByCategory = expenses.reduce(
        (acc, expense) => {
          const existing = acc.find((e) => e.category === expense.category)
          if (existing) {
            existing.amount += expense.amount
          } else {
            acc.push({ category: expense.category, amount: expense.amount })
          }
          return acc
        },
        [] as Array<{ category: string; amount: number }>,
      )

      const response = await fetch("/api/recommendations", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ expenses: expensesByCategory }),
      })
      const data = await response.json()
      setRecommendations(data.recommendations || [])
    } catch (error) {
      console.error("Error fetching recommendations:", error)
      if (expenses.length === 0) {
        setRecommendations([
          {
            id: "welcome-1",
            title: "¡Bienvenido a AhorraMax! 🎉",
            description:
              "Comienza agregando tus primeros gastos para recibir recomendaciones personalizadas de IA. Te ayudaremos a encontrar las mejores ofertas y lugares en Ecuador para ahorrar más.",
            potentialSavings: 0,
            category: "Inicio",
            location: "Ecuador",
          },
        ])
      } else {
        // Fallback recommendations
        setRecommendations([
          {
            id: "1",
            title: "Reduce gastos en restaurantes",
            description:
              "Has gastado $1,200 en restaurantes este mes. Cocinar en casa 2 veces más por semana podría ahorrarte hasta $400.",
            potentialSavings: 400,
            category: "Alimentación",
          },
          {
            id: "2",
            title: "Optimiza tu transporte",
            description: "Considera usar transporte público o compartir viajes. Podrías ahorrar $200 mensuales.",
            potentialSavings: 200,
            category: "Transporte",
          },
          {
            id: "3",
            title: "Revisa suscripciones",
            description: "Tienes 5 suscripciones activas. Cancela las que no uses y ahorra $150 al mes.",
            potentialSavings: 150,
            category: "Entretenimiento",
          },
        ])
      }
    } finally {
      setLoading(false)
    }
  }

  const handleAcceptRecommendation = (rec: Recommendation) => {
    if (!acceptedRecommendations.has(rec.id)) {
      onAcceptSavings(rec.potentialSavings)
      setAcceptedRecommendations(new Set([...acceptedRecommendations, rec.id]))

      // Vibración del celular si está disponible
      if (navigator.vibrate) {
        navigator.vibrate([100, 50, 100])
      }
    }
  }

  useEffect(() => {
    fetchRecommendations()
  }, [expenses])

  if (!isVisible) return null

  return (
    <Card className="p-6 bg-gradient-to-br from-primary/5 to-secondary/5">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-primary to-secondary flex items-center justify-center shadow-lg">
            <Sparkles className="w-6 h-6 text-white" />
          </div>
          <div>
            <h2 className="text-xl font-bold text-foreground">Recomendaciones de IA</h2>
            <p className="text-sm text-foreground font-medium">Powered by Gemini ✨</p>
          </div>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="icon"
            className="rounded-full bg-transparent hover:bg-primary/10 border-2"
            onClick={fetchRecommendations}
            disabled={loading}
          >
            <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
          </Button>
          <Button
            variant="outline"
            size="icon"
            className="rounded-full bg-transparent hover:bg-red-500/10 border-2 hover:border-red-500"
            onClick={() => setIsVisible(false)}
            title="Cerrar recomendaciones"
          >
            <X className="w-4 h-4" />
          </Button>
        </div>
      </div>

      <div className="space-y-4">
        {recommendations.map((rec, index) => {
          const isAccepted = acceptedRecommendations.has(rec.id)
          return (
            <div
              key={rec.id}
              className={`p-5 rounded-2xl border-2 transition-all duration-300 hover:-translate-y-1 ${
                isAccepted
                  ? "bg-primary/10 border-primary/40"
                  : "bg-card border-primary/20 hover:border-primary/40 hover:shadow-lg"
              }`}
              style={{ animationDelay: `${index * 100}ms` }}
            >
              <div className="flex items-start justify-between gap-4 mb-3">
                <h3 className="font-bold text-foreground text-lg">{rec.title}</h3>
                <span
                  className={`text-lg font-bold whitespace-nowrap px-3 py-1 rounded-full ${
                    isAccepted ? "bg-primary text-white" : "text-primary bg-primary/10"
                  }`}
                >
                  +${rec.potentialSavings}
                </span>
              </div>
              <p className="text-sm text-foreground text-pretty leading-relaxed mb-3">{rec.description}</p>
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="text-xs px-3 py-1.5 rounded-full bg-gradient-to-r from-primary to-secondary text-white font-bold">
                    {rec.category}
                  </span>
                  {rec.location && (
                    <span className="text-xs px-3 py-1.5 rounded-full bg-gradient-to-r from-accent to-primary text-white font-bold">
                      {rec.location}
                    </span>
                  )}
                </div>
                {!isAccepted && rec.potentialSavings > 0 && (
                  <Button
                    size="sm"
                    onClick={() => handleAcceptRecommendation(rec)}
                    className="rounded-xl bg-gradient-to-r from-primary to-secondary text-white hover:scale-105 transition-transform"
                  >
                    Aceptar
                  </Button>
                )}
                {isAccepted && (
                  <span className="text-xs text-primary font-bold flex items-center gap-1">
                    <Sparkles className="w-4 h-4" />
                    Ahorraste!
                  </span>
                )}
              </div>
            </div>
          )
        })}
      </div>
    </Card>
  )
}
