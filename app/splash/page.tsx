"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { Sparkles } from "lucide-react"

const savingsTips = [
  "Ahorra el 20% de tus ingresos cada mes",
  "Evita compras impulsivas, espera 24 horas",
  "Prepara comida en casa, ahorra hasta 40%",
  "Cancela suscripciones que no uses",
  "Usa transporte público cuando sea posible",
  "Compara precios antes de comprar",
  "Establece metas de ahorro claras",
  "Revisa tus gastos cada semana",
  "Compra en Mi Comisariato los miércoles, hay descuentos especiales",
  "Evita comer fuera, cocinar en casa ahorra hasta $200/mes",
  "Usa apps de descuentos como Rappi y Uber Eats con cupones",
  "Compra productos genéricos, ahorras hasta 30%",
  "Planifica tus compras con lista, evita gastos innecesarios",
  "Aprovecha los días sin IVA en Ecuador",
  "Compra en mercados locales, son más económicos",
  "Usa bicicleta o camina distancias cortas, ahorra en transporte",
  "Compra en Santa María en horarios de ofertas nocturnas",
  "Aprovecha el 2x1 en Tía los fines de semana",
  "Revisa tu suscripción de Netflix, comparte con familia",
  "Usa WiFi público en cafés para ahorrar datos móviles",
  "Compra ropa en temporada de liquidación, ahorras 50%",
  "Prepara café en casa, ahorras $60/mes vs cafeterías",
  "Lleva lunch al trabajo, ahorras $100/mes",
  "Compra productos de temporada, son más baratos",
  "Usa cupones digitales antes de comprar online",
  "Repara en vez de reemplazar cuando sea posible",
  "Apaga luces y electrodomésticos, reduce tu factura eléctrica",
  "Usa termos para agua, evita comprar botellas",
  "Compra al por mayor en Makro o PriceSmart",
]

export default function SplashPage() {
  const router = useRouter()
  const [tip, setTip] = useState("")

  useEffect(() => {
    // Seleccionar un tip aleatorio
    const randomTip = savingsTips[Math.floor(Math.random() * savingsTips.length)]
    setTip(randomTip)

    // Redirigir al dashboard después de 3 segundos
    const timer = setTimeout(() => {
      router.push("/dashboard")
    }, 3000)

    return () => clearTimeout(timer)
  }, [router])

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4 overflow-hidden relative">
      {/* Fondo decorativo */}
      <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-secondary/5 to-accent/5" />
      <div className="absolute top-20 left-20 w-64 h-64 bg-primary/10 rounded-full blur-3xl animate-pulse" />
      <div className="absolute bottom-20 right-20 w-80 h-80 bg-secondary/10 rounded-full blur-3xl animate-pulse delay-700" />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-accent/10 rounded-full blur-3xl animate-pulse delay-1000" />

      <div className="relative z-10 text-center space-y-8 max-w-md mx-auto">
        {/* Logo animado */}
        <div className="relative">
          <div className="w-32 h-32 mx-auto rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-6xl font-bold text-white shadow-2xl animate-in zoom-in duration-700">
            $
          </div>
          <div className="absolute inset-0 w-32 h-32 mx-auto rounded-full bg-gradient-to-br from-primary to-secondary animate-ping opacity-20" />
        </div>

        {/* Nombre de la app */}
        <div className="space-y-2 animate-in fade-in slide-in-from-bottom-4 duration-700 delay-300">
          <h1 className="text-5xl font-bold bg-gradient-to-r from-primary via-secondary to-accent bg-clip-text text-transparent">
            AhorraMax
          </h1>
          <p className="text-lg text-foreground font-medium">Tu asistente financiero inteligente</p>
        </div>

        {/* Tip de ahorro */}
        <div className="animate-in fade-in slide-in-from-bottom-4 duration-700 delay-700">
          <div className="p-6 rounded-3xl bg-gradient-to-br from-primary/10 via-secondary/10 to-accent/10 border-2 border-primary/20 backdrop-blur-sm">
            <div className="flex items-center justify-center gap-2 mb-3">
              <Sparkles className="w-5 h-5 text-primary animate-pulse" />
              <span className="text-sm font-bold text-primary uppercase tracking-wide">Consejo del día</span>
            </div>
            <p className="text-foreground font-medium text-lg text-balance">{tip}</p>
          </div>
        </div>

        {/* Indicador de carga */}
        <div className="animate-in fade-in duration-700 delay-1000">
          <div className="w-48 h-2 mx-auto bg-border rounded-full overflow-hidden">
            <div className="h-full bg-gradient-to-r from-primary via-secondary to-accent animate-loading-bar rounded-full" />
          </div>
        </div>
      </div>
    </div>
  )
}
