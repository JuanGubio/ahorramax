import { type NextRequest, NextResponse } from "next/server"

export async function POST(req: NextRequest) {
  try {
    const { currentGoal } = await req.json()

    // Generar recomendación basada en la meta actual
    const suggestedGoal = Math.round(currentGoal * 1.5) // 50% más que la meta actual

    const recommendations = [
      `🎯 ¡Increíble progreso! Te reto a alcanzar $${suggestedGoal.toLocaleString()} como tu siguiente meta. ¡Tú puedes!`,
      `💪 ¡Vas muy bien! Tu próximo desafío: ahorrar $${suggestedGoal.toLocaleString()}. ¡Lo lograrás!`,
      `🌟 ¡Excelente! Ahora apunta a $${suggestedGoal.toLocaleString()}. Cada peso cuenta hacia tus sueños.`,
      `🚀 ¡Sigue así! La próxima meta es $${suggestedGoal.toLocaleString()}. El éxito está en tus manos.`,
    ]

    const recommendation = recommendations[Math.floor(Math.random() * recommendations.length)]

    // Si quieres usar Gemini real, descomenta esto y asegúrate de tener una API key válida:
    /*
    if (process.env.GEMINI_API_KEY) {
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${process.env.GEMINI_API_KEY}`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            contents: [
              {
                parts: [
                  {
                    text: `El usuario tiene una meta de ahorro de $${currentGoal}. Como experto en finanzas personales y motivación, sugiere una nueva meta de ahorro desafiante pero alcanzable (que sea mayor). Responde en una sola frase corta y motivadora, mencionando la cantidad específica en dólares. Ejemplo: "¡Excelente! Te reto a alcanzar $7,500 como tu siguiente meta. ¡Tú puedes!" Sé breve, máximo 2 líneas.`,
                  },
                ],
              },
            ],
          }),
        },
      )

      if (response.ok) {
        const data = await response.json()
        const aiRecommendation = data.candidates?.[0]?.content?.parts?.[0]?.text
        if (aiRecommendation) {
          return NextResponse.json({ recommendation: aiRecommendation })
        }
      }
    }
    */

    return NextResponse.json({ recommendation })
  } catch (error) {
    console.error("Error en streak-recommendation:", error)
    return NextResponse.json(
      {
        recommendation: "¡Excelente meta! Sigue así y alcanzarás tus objetivos financieros.",
      },
      { status: 200 },
    )
  }
}
