"use client"

import { useState, useEffect } from "react"
import { DollarSign } from "lucide-react"

const motivationalMessages = [
  "¡Cada peso ahorrado es un paso hacia tu libertad financiera! 💪",
  "¿Realmente necesitas eso? ¡Piénsalo dos veces! 🤔",
  "¡Excelente! Llevas un buen control de tus finanzas 🎉",
  "Recuerda: Ahorrar hoy es disfrutar mañana 🌟",
  "¡Sigue así! Tus metas están cada vez más cerca 🎯",
  "Pequeños ahorros = Grandes resultados 📈",
  "¿Y si inviertes ese dinero en lugar de gastarlo? 💡",
  "¡Tu yo del futuro te lo agradecerá! 🙌",
  "Cada 'no' a un gasto innecesario es un 'sí' a tus sueños ✨",
  "¡Estás haciendo un trabajo increíble! Sigue adelante 🚀",
  "El dinero no crece en los árboles, pero tú puedes hacerlo crecer 🌱",
  "Compara precios antes de comprar, ¡siempre hay mejores ofertas! 🔍",
  "¿Café todos los días? Prepáralo en casa y ahorra más de $50 al mes ☕",
  "Las pequeñas acciones de hoy son los grandes logros de mañana 💫",
  "Prioriza necesidades sobre deseos, tu cartera te lo agradecerá 🎁",
  "Haz una lista antes de comprar, evita gastos impulsivos 📝",
  "¿Cuánto tiempo trabajaste para comprarte eso? Piénsalo 🤨",
  "Un presupuesto no te limita, ¡te da libertad! 🗺️",
  "Evita las deudas innecesarias, son el enemigo del ahorro 🚫",
  "¡Celebra tus logros financieros! Cada ahorro cuenta 🥳",
  "Compara ofertas en supermercados, hay diferencias grandes 🛒",
  "Usa transporte público cuando puedas, ahorra en gasolina 🚌",
  "Cocina en casa, es más saludable y económico 🍳",
  "Planifica tus comidas de la semana para no desperdiciar 📅",
  "Aprovecha los descuentos, pero solo si realmente lo necesitas 🏷️",
  "Establece metas de ahorro realistas y alcanzables 🎯",
  "Revisa tus suscripciones, ¿realmente usas todas? 📱",
  "Compra productos de temporada, son más baratos 🥬",
  "Ahorra el 10% de cada ingreso que recibas 💰",
  "Busca alternativas gratuitas para entretenimiento 🎭",
  "Repara en lugar de reemplazar cuando sea posible 🔧",
  "Compra a granel para ahorrar a largo plazo 📦",
  "Negocia precios, muchas veces es posible 🤝",
  "Evita las tarjetas de crédito para gastos innecesarios 💳",
  "Ahorra primero, gasta después con lo que sobre 💪",
  "Establece un fondo de emergencia, tu red de seguridad 🛡️",
  "Compra ropa de calidad que dure más tiempo 👕",
  "Usa cupones y códigos de descuento siempre que puedas 🎫",
  "Vende lo que no uses, genera ingresos extra 💵",
  "Educate financieramente, el conocimiento es poder 📚",
]

export function MoneyMascot() {
  const [isVisible, setIsVisible] = useState(false)
  const [message, setMessage] = useState("")
  const [position] = useState({ bottom: 180, right: 24 })

  useEffect(() => {
    // Mostrar mascota cada 30 segundos
    const interval = setInterval(() => {
      const randomMessage = motivationalMessages[Math.floor(Math.random() * motivationalMessages.length)]
      setMessage(randomMessage)
      setIsVisible(true)

      // Ocultar después de 8 segundos
      setTimeout(() => {
        setIsVisible(false)
      }, 8000)
    }, 30000)

    // Mostrar inmediatamente al cargar
    setTimeout(() => {
      const randomMessage = motivationalMessages[Math.floor(Math.random() * motivationalMessages.length)]
      setMessage(randomMessage)
      setIsVisible(true)
      setTimeout(() => setIsVisible(false), 8000)
    }, 5000)

    return () => clearInterval(interval)
  }, [])

  if (!isVisible) return null

  return (
    <div
      className="fixed z-30 animate-in slide-in-from-bottom-5 duration-500"
      style={{ bottom: `${position.bottom}px`, right: `${position.right}px` }}
    >
      <div className="relative">
        {/* Mensaje */}
        <div className="absolute bottom-full right-0 mb-4 mr-2 max-w-xs">
          <div className="bg-card rounded-2xl shadow-2xl p-4 border-2 border-primary relative">
            <button
              onClick={() => setIsVisible(false)}
              className="absolute -top-2 -right-2 w-6 h-6 rounded-full bg-red-500 hover:bg-red-600 text-white flex items-center justify-center transition-colors shadow-lg"
              title="Cerrar"
            >
              <span className="text-xs font-bold">×</span>
            </button>
            <p className="text-sm font-medium text-foreground text-pretty">{message}</p>
            {/* Flecha del bocadillo */}
            <div className="absolute -bottom-2 right-8 w-4 h-4 bg-card border-r-2 border-b-2 border-primary rotate-45" />
          </div>
        </div>

        {/* Mascota */}
        <div className="w-20 h-20 rounded-full bg-gradient-to-br from-primary via-secondary to-accent flex items-center justify-center shadow-2xl animate-bounce cursor-pointer hover:scale-110 transition-transform border-4 border-card">
          <DollarSign className="w-10 h-10 text-white font-bold" strokeWidth={3} />
        </div>

        {/* Efecto de brillo */}
        <div className="absolute inset-0 rounded-full bg-gradient-to-br from-white/40 to-transparent pointer-events-none" />
      </div>
    </div>
  )
}
