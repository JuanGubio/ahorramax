import { type NextRequest, NextResponse } from "next/server"

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { expenses } = body

    const recommendations = generateRecommendations(expenses)

    return NextResponse.json({ recommendations })
  } catch (error) {
    console.error("Error generating recommendations:", error)
    return NextResponse.json({ error: "Failed to generate recommendations" }, { status: 500 })
  }
}

function generateRecommendations(expenses: Array<{ category: string; amount: number }>) {
  const recommendations = []

  // Analizar gastos en restaurantes
  const restaurantExpense = expenses.find((e) => e.category === "Restaurantes")
  if (restaurantExpense && restaurantExpense.amount > 1000) {
    recommendations.push({
      id: "1",
      title: "🍳 Cocina en casa y ahorra mucho más",
      description: `Has gastado $${restaurantExpense.amount.toLocaleString()} en restaurantes. En Ecuador: compra en Mi Comisariato (20% off los martes) o Santa María (2x1 viernes). Los mercados como Iñaquito tienen productos 40% más baratos. Cocinando en casa 3 veces/semana ahorras $${Math.round(restaurantExpense.amount * 0.4)}. 💡 Hornados típicos desde $3.50!`,
      potentialSavings: Math.round(restaurantExpense.amount * 0.4),
      category: "Alimentación",
      location: "Mi Comisariato, Santa María, Mercado Iñaquito",
    })
  }

  // Analizar transporte
  const transportExpense = expenses.find((e) => e.category === "Transporte")
  if (transportExpense && transportExpense.amount > 500) {
    recommendations.push({
      id: "2",
      title: "🚌 Usa transporte público inteligentemente",
      description: `Gastas $${transportExpense.amount.toLocaleString()} en transporte. En Quito: tarjeta de transporte $0.35 vs $0.50 efectivo. Usa Ecovía/Metrobús/Trolebús. BiciQuito gratis primera hora. Uber Pool ahorra 30%. Combinando transporte público reduces gastos en $${Math.round(transportExpense.amount * 0.35)}. ¡Súper económico!`,
      potentialSavings: Math.round(transportExpense.amount * 0.35),
      category: "Transporte",
      location: "Sistema Integrado Quito, BiciQuito, Uber Pool",
    })
  }

  // Analizar entretenimiento
  const entertainmentExpense = expenses.find((e) => e.category === "Entretenimiento")
  if (entertainmentExpense && entertainmentExpense.amount > 400) {
    recommendations.push({
      id: "3",
      title: "📺 Optimiza tus suscripciones digitales",
      description: `Inviertes $${entertainmentExpense.amount.toLocaleString()} en entretenimiento. Comparte Netflix/Spotify. Prime Video incluido con Amazon Prime ($5/mes). YouTube Premium Familiar $8.99 para 6 personas. Cancela las que no uses y ahorra $${Math.round(entertainmentExpense.amount * 0.35)} mensuales. ¡Más contenido, menos gasto!`,
      potentialSavings: Math.round(entertainmentExpense.amount * 0.35),
      category: "Entretenimiento",
      location: "Amazon Prime Ecuador, YouTube Premium",
    })
  }

  // Analizar compras
  const shoppingExpense = expenses.find((e) => e.category === "Compras")
  if (shoppingExpense && shoppingExpense.amount > 1000) {
    recommendations.push({
      id: "4",
      title: "🛍️ Compra inteligente con mega ofertas",
      description: `Has gastado $${shoppingExpense.amount.toLocaleString()} en compras. En Ecuador: Tía (miércoles 40% off abarrotes), Aki (50% marca propia), Megamaxi (2x1 fines de semana). Usa Picap para comparar precios. San Marino Outlet tiene ropa 50% off. Ahorra $${Math.round(shoppingExpense.amount * 0.45)} comprando inteligente!`,
      potentialSavings: Math.round(shoppingExpense.amount * 0.45),
      category: "Compras",
      location: "Tía, Aki, Megamaxi, San Marino Outlet",
    })
  }

  // Recomendación de bancos y tarjetas
  const totalExpenses = expenses.reduce((sum, e) => sum + e.amount, 0)
  if (totalExpenses > 2000 && recommendations.length < 5) {
    recommendations.push({
      id: "5",
      title: "💳 Aprovecha cashback de bancos ecuatorianos",
      description: `Con gastos de $${totalExpenses.toLocaleString()}, usa tarjetas con cashback. Banco Pichincha Mi Banco: hasta 5% cashback. Produbanco: puntos reembolsables. Banco Guayaquil: sin cuota año 1. Recupera hasta $${Math.round(totalExpenses * 0.05)}/mes. ¡Tu dinero trabaja para ti!`,
      potentialSavings: Math.round(totalExpenses * 0.05),
      category: "Finanzas",
      location: "Banco Pichincha, Produbanco, Banco Guayaquil",
    })
  }

  // Recomendación general de ahorro
  if (recommendations.length < 3) {
    recommendations.push({
      id: "6",
      title: "💰 Crea tu fondo de emergencia hoy",
      description: `Con gastos de $${totalExpenses.toLocaleString()}, ahorra 15% mensual ($${Math.round(totalExpenses * 0.15)}). Bancos ecuatorianos como Pichincha y Guayaquil ofrecen cuentas de ahorro con hasta 3% interés anual. Un fondo de emergencia te da tranquilidad y seguridad financiera. ¡Empieza hoy!`,
      potentialSavings: Math.round(totalExpenses * 0.15),
      category: "Ahorro",
      location: "Banco Pichincha, Banco Guayaquil",
    })
  }

  return recommendations.slice(0, 5) // Retornar las 5 mejores recomendaciones
}
