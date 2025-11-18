import { type NextRequest, NextResponse } from "next/server"

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { expenses } = body

    // Aquí se integraría con Gemini API
    // Por ahora, generamos recomendaciones inteligentes basadas en los gastos

    const totalExpenses = expenses.reduce((sum: number, expense: { amount: number }) => sum + expense.amount, 0)

    // Encontrar la categoría con más gastos
    const topCategory = expenses.reduce(
      (max: { category: string; amount: number }, expense: { category: string; amount: number }) =>
        expense.amount > max.amount ? expense : max,
      { category: "", amount: 0 },
    )

    // Generar recomendación personalizada
    let recommendation = ""

    if (topCategory.category === "Restaurantes") {
      recommendation = `🍽️ Detectamos que entraste a tu banca móvil. Veo que has gastado $${topCategory.amount.toLocaleString()} en restaurantes. Antes de pedir comida, ¿qué tal si cocinas en casa hoy? Podrías ahorrar hasta $${Math.round(topCategory.amount * 0.3)} este mes. ¡Tu bolsillo te lo agradecerá! 💰`
    } else if (topCategory.category === "Entretenimiento") {
      recommendation = `🎮 ¡Hola! Notamos que entraste a tu app bancaria. Has gastado $${topCategory.amount.toLocaleString()} en entretenimiento. ¿Realmente necesitas esa compra ahora? Esperar 24 horas te ayuda a decidir mejor. ¡Ahorra hoy, disfruta mañana! ✨`
    } else if (topCategory.category === "Compras") {
      recommendation = `🛍️ ¡Momento! Antes de comprar, pregúntate: ¿Lo necesito o lo quiero? Has gastado $${topCategory.amount.toLocaleString()} en compras. Aplicar la regla de las 24 horas podría ahorrarte $${Math.round(topCategory.amount * 0.4)}. ¡Piénsalo! 🤔`
    } else if (topCategory.category === "Transporte") {
      recommendation = `🚗 Detectamos actividad en tu banca móvil. Gastas $${topCategory.amount.toLocaleString()} en transporte. ¿Has considerado compartir viajes o usar transporte público? Podrías ahorrar hasta $${Math.round(topCategory.amount * 0.25)} al mes. 🚌`
    } else {
      recommendation = `💡 ¡Hola! Vemos que entraste a tu banca móvil. Llevas $${totalExpenses.toLocaleString()} en gastos este mes. Antes de gastar, pregúntate: ¿Es necesario? ¿Puedo esperar? Cada peso ahorrado te acerca a tus metas. ¡Tú puedes! 🎯`
    }

    // Aquí iría la integración real con Gemini:
    /*
    const response = await fetch('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.GEMINI_API_KEY}`
      },
      body: JSON.stringify({
        contents: [{
          parts: [{
            text: `Eres un asistente financiero amigable. El usuario acaba de entrar a su banca móvil y tiene estos gastos: ${JSON.stringify(expenses)}. Dale una recomendación breve y motivacional sobre en qué debería o no gastar para ahorrar dinero. Sé específico y usa emojis.`
          }]
        }]
      })
    })
    */

    return NextResponse.json({ recommendation })
  } catch (error) {
    console.error("Error generating banking recommendation:", error)
    return NextResponse.json(
      {
        recommendation:
          "💡 Detectamos que entraste a tu banca móvil. Antes de gastar, considera: ¿Es necesario? ¿Puedes esperar? Ahorrar hoy es invertir en tu futuro. ¡Piénsalo dos veces!",
      },
      { status: 200 },
    )
  }
}
