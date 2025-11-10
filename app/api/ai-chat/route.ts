import { type NextRequest, NextResponse } from "next/server"

function getLocationName(lat: number, lon: number): string {
  // Coordenadas aproximadas de zonas de Quito
  if (lat >= -0.25 && lat <= -0.2 && lon >= -78.5 && lon <= -78.45) {
    return "Condado Shopping, Quito"
  }
  if (lat >= -0.22 && lat <= -0.18 && lon >= -78.5 && lon <= -78.45) {
    return "Quicentro Shopping, Quito"
  }
  if (lat >= -0.23 && lat <= -0.19 && lon >= -78.52 && lon <= -78.48) {
    return "Centro Histórico, Quito"
  }
  if (lat >= -0.2 && lat <= -0.16 && lon >= -78.5 && lon <= -78.46) {
    return "La Carolina, Quito"
  }
  return "Quito"
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { message, hasImage, userLocation } = body

    let locationContext = "Quito"
    if (userLocation) {
      locationContext = getLocationName(userLocation.lat, userLocation.lon)
    }

    if (hasImage) {
      return NextResponse.json({
        response: `¡Analicé tu imagen! Encontré el producto que buscas:\n\n🏪 Mejores lugares donde encontrarlo en ${locationContext}:\n\n• Mall del Condado\n  → Tiendas deportivas con hasta 40% desc\n  📍 Condado Shopping, Quito\n  ⏰ Oferta válida hasta el domingo\n\n• Centro Comercial El Recreo\n  → Marcas internacionales -30%\n  📍 Av. Amazonas, Quito\n  🎁 2x1 en compras mayores a $50\n\n• Quicentro Shopping\n  → Outlet de marcas premium\n  📍 Av. 6 de Diciembre, Quito\n  💳 10% adicional con tarjeta\n\n💡 El mejor descuento está en Condado Shopping: ¡ahorras hasta $35!`,
        imageUrl: "/descuentos-supermercado-ofertas-ecuador.jpg",
        location: `Condado Shopping - ${locationContext}`,
      })
    }

    const response = generateAIResponse(message.toLowerCase(), locationContext)

    return NextResponse.json(response)
  } catch (error) {
    console.error("Error in AI chat:", error)
    return NextResponse.json({ error: "Failed to process message" }, { status: 500 })
  }
}

function generateAIResponse(
  message: string,
  location = "Quito",
): { response: string; imageUrl?: string; location?: string } {
  if (message.includes("kfc") || message.includes("combo familiar")) {
    return {
      response: `🍗 ¡Excelente elección! Aquí está la oferta de KFC en ${location}:\n\n💰 COMBO FAMILIAR A $12.99\n• 8 piezas de pollo\n• Papas familiares\n• Ensalada de col\n• 4 bebidas medianas\n\n📍 Ubicaciones en ${location}:\n• KFC Plaza de las Américas\n• KFC Quicentro Norte\n• KFC El Recreo\n• KFC 6 de Diciembre\n\n⏰ Oferta válida hasta fin de mes\n💡 Ahorro: $6 vs precio regular ($18.99)\n\n¿Quieres ver otras ofertas de comida rápida?`,
      imageUrl: "/kfc-combo-familiar-pollo-promocion.jpg",
      location: "KFC - Plaza de las Américas, Quito",
    }
  }

  if (message.includes("pizza hut") || message.includes("pizza") || message.includes("2x1")) {
    return {
      response: `🍕 ¡Oferta especial de Pizza Hut hoy en ${location}!\n\n🔥 2X1 EN PIZZAS MEDIANAS\n• Aplica para todas las variedades\n• Solo para pedidos en tienda o app\n• Válido solo HOY\n\n📍 Pizza Hut en ${location}:\n• CC Quicentro Sur\n• Av. República del Salvador\n• La Carolina\n• Mall El Jardín\n\n💰 Ahorro aproximado: $14.99 por pizza extra gratis\n⏰ Horario: 11:00 AM - 10:00 PM\n\n¿Necesitas el número para ordenar?`,
      imageUrl: "/pizza-hut-2x1-ofertas-pizzas-medianas-promocion.jpg",
      location: "Pizza Hut - Quicentro Sur, Quito",
    }
  }

  if (
    message.includes("comida") ||
    message.includes("restaurante") ||
    message.includes("comer") ||
    message.includes("ofertas de comida")
  ) {
    return {
      response: `🍽️ ¡Te tengo las mejores ofertas de comida en ${location}!\n\n🔥 OFERTAS HOY:\n• 🍕 Pizza Hut: 2x1 en pizzas medianas\n• 🍗 KFC: Combo familiar $12.99 (ahorra $6)\n• 🍔 McDonald's: McCombo a $4.99\n• 🌮 Taco Bell: Martes de tacos 3x$5\n\n🏪 SUPERMERCADOS:\n• Mi Comisariato: 20% en productos frescos (martes)\n• Santa María: 2x1 en carnes (viernes)\n• Tía: Miércoles de oferta 40% en abarrotes\n\n🍲 RESTAURANTES ECONÓMICOS:\n• Hornado típico: desde $3.50\n• Almuerzos ejecutivos: $2.50-$4.00\n• Mercados locales: comida casera $2-$3\n\n💡 Cocinar en casa ahorra $400/mes. ¿Quieres recetas económicas?`,
      imageUrl: "/restaurantes-comida-rapida-ofertas-descuentos-ecua.jpg",
      location: "Mi Comisariato - Av. Amazonas, Quito",
    }
  }

  if (
    message.includes("transporte") ||
    message.includes("taxi") ||
    message.includes("uber") ||
    message.includes("bus") ||
    message.includes("descuento en tarjeta")
  ) {
    return {
      response: `🚌 ¡Ahorra en transporte en ${location}!\n\n💳 TRANSPORTE PÚBLICO:\n• Tarjeta recargable: $0.35 vs $0.50 efectivo\n• Ahorro mensual: $27 (60 viajes)\n• Recarga en estaciones y tiendas autorizadas\n\n🚕 APPS DE TRANSPORTE:\n• Uber Pool: ahorra hasta 30%\n• Cabify Compartido: descuento 25%\n• InDriver: negocia tu tarifa\n\n🚲 ALTERNATIVAS GRATIS:\n• BiciQuito: primera hora gratis\n• CicloRutas: domingos sin autos\n\n📍 Rutas económicas:\n• Ecovía, Metrobús, Trolebús: $0.35\n• Metrovía Guayaquil: $0.30\n\n💡 Combinar transporte público + apps compartidas = $250/mes de ahorro`,
      imageUrl: "/transporte-publico-quito-bus-tarjeta-ecovia-metrob.jpg",
      location: "Estación Trolebús - Plaza Grande, Quito",
    }
  }

  if (
    message.includes("supermercado") ||
    message.includes("compras") ||
    message.includes("descuento") ||
    message.includes("oferta") ||
    message.includes("mi comisariato") ||
    message.includes("lácteos")
  ) {
    return {
      response: `🛒 ¡Las mejores ofertas en supermercados de ${location}!\n\n🔥 OFERTAS DE LA SEMANA:\n\n• 🏪 Mi Comisariato\n  → 30% en lácteos (hasta viernes)\n  → Club digital: cupones exclusivos\n  📍 Múltiples ubicaciones\n\n• 🛍️ Tía\n  → Miércoles: 40% en abarrotes\n  → Marca propia hasta 50% más barata\n  📍 Av. Maldonado, Quito\n\n• 🏬 Aki\n  → Productos de limpieza -50%\n  → 2x1 en marcas selectas\n  📍 Centro Comercial El Recreo\n\n• 🌟 Supermaxi\n  → Fines de semana: 2x1 variado\n  → Tarjeta Supermaxi Club: puntos dobles\n  📍 Mall El Jardín\n\n💡 TIPS DE AHORRO:\n→ Mercado Mayorista: compra al por mayor (-60%)\n→ Compara precios con app Picap\n→ Marcas propias: misma calidad, -40%\n\n¿Buscas algo específico?`,
      imageUrl: "/supermercado-ofertas-promociones-descuentos-mi-com.jpg",
      location: "Mi Comisariato - Av. Amazonas, Quito",
    }
  }

  if (
    message.includes("ropa") ||
    message.includes("vestir") ||
    message.includes("moda") ||
    message.includes("zapatos") ||
    message.includes("juguete")
  ) {
    return {
      response: `👕 ¡Encuentra ropa y accesorios con descuentos increíbles en ${location}!\n\n🔥 OFERTAS ACTUALES:\n\n• 🏪 De Prati\n  → Mega sale: hasta 70% off\n  → Próximo sale: cada 3 meses\n  📍 CC El Recreo, Quicentro\n\n• 👟 Marathon Sports\n  → Deportiva: hasta 50% descuento\n  → Liquidación fin de temporada\n  📍 Múltiples ubicaciones\n\n• 🎒 Totto\n  → 2x1 en mochilas selectas\n  → Descuento estudiantes: 15%\n  📍 Mall El Jardín\n\n• 🛍️ OUTLETS:\n  → San Marino Outlet: -50% marcas\n  → San Luis Shopping: liquidaciones\n  📍 Norte de Quito\n\n💡 TIPS:\n→ Compra fuera de temporada: -60%\n→ Black Friday Ecuador: noviembre\n→ Cyber Monday: descuentos online\n\n¿Buscas algo en particular?`,
      imageUrl: "/ropa-zapatos-juguetes-tienda-ofertas-descuentos-mo.jpg",
      location: "De Prati - CC El Recreo, Quito",
    }
  }

  return {
    response: `👋 ¡Hola! Soy tu asistente de ahorros con IA.\n\n🔍 Puedo ayudarte con:\n\n💰 OFERTAS Y DESCUENTOS:\n• Supermercados (Mi Comisariato, Tía, Aki)\n• Restaurantes y comida rápida\n• Ropa y calzado\n• Transporte público y apps\n\n📊 ANÁLISIS PERSONALIZADO:\n• Subir foto de producto para buscar descuentos\n• Comparar precios entre tiendas\n• Recomendaciones basadas en tus gastos\n\n💡 CONSEJOS DE AHORRO:\n• Mejores días para comprar\n• Tarjetas con beneficios\n• Alternativas económicas\n\n¿Qué te gustaría buscar? Puedes escribir el nombre del producto o subirme una foto para encontrarte el mejor precio en ${location}.`,
    imageUrl: "/asistente-financiero-ia-ahorros-ofertas-descuentos.jpg",
  }
}
