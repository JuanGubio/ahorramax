import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Sparkles, TrendingUp, Target, Shield } from "lucide-react"

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-primary/10 via-secondary/5 to-background">
      {/* Header */}
      <header className="border-b border-border bg-background/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-2xl font-bold text-white">
              $
            </div>
            <span className="text-2xl font-bold bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
              AhorraMax
            </span>
          </div>
          <nav className="hidden md:flex items-center gap-6">
            <Link href="#features" className="text-foreground/70 hover:text-foreground transition-colors">
              Características
            </Link>
            <Link href="#how-it-works" className="text-foreground/70 hover:text-foreground transition-colors">
              Cómo funciona
            </Link>
            <Button asChild variant="outline" className="rounded-full bg-transparent">
              <Link href="/login">Iniciar sesión</Link>
            </Button>
          </nav>
        </div>
      </header>

      {/* Hero Section */}
      <section className="container mx-auto px-4 py-16 md:py-24">
        <div className="max-w-4xl mx-auto text-center space-y-8">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 text-primary text-sm font-medium">
            <Sparkles className="w-4 h-4" />
            <span>Ahorra inteligentemente con IA</span>
          </div>

          <h1 className="text-4xl md:text-6xl font-bold text-balance leading-tight">
            Tu asistente financiero
            <span className="block bg-gradient-to-r from-primary via-secondary to-accent bg-clip-text text-transparent">
              impulsado por IA
            </span>
          </h1>

          <p className="text-xl text-foreground max-w-2xl mx-auto text-pretty">
            AhorraMax analiza tus gastos y te da recomendaciones personalizadas para ahorrar más dinero cada mes
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Button
              asChild
              size="lg"
              className="rounded-full bg-primary hover:bg-primary-dark text-white px-8 h-14 text-lg"
            >
              <Link href="/register">Comenzar gratis</Link>
            </Button>
            <Button asChild size="lg" variant="outline" className="rounded-full px-8 h-14 text-lg bg-transparent">
              <Link href="#how-it-works">Ver cómo funciona</Link>
            </Button>
          </div>
        </div>

        {/* Hero Image/Mockup */}
        <div className="mt-16 max-w-5xl mx-auto">
          {/* Phone design with app logo */}
          <div className="relative mx-auto w-full max-w-sm">
            <div className="relative rounded-[3rem] overflow-hidden shadow-2xl border-8 border-gray-900 bg-gray-900">
              {/* Phone notch */}
              <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-7 bg-gray-900 rounded-b-3xl z-10" />

              {/* Screen content */}
              <div className="relative bg-gradient-to-b from-primary/10 via-secondary/5 to-background pt-8">
                <div className="flex flex-col items-center justify-center py-12 px-6">
                  <div className="w-32 h-32 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-6xl font-bold text-white shadow-2xl mb-6 animate-pulse">
                    $
                  </div>
                  <h2 className="text-3xl font-bold text-center mb-2">AhorraMax</h2>
                  <p className="text-center text-foreground">Tu asistente financiero IA</p>
                </div>

                {/* Preview cards */}
                <div className="px-4 pb-8 space-y-3">
                  <div className="bg-card p-4 rounded-2xl border-2 border-primary/20 shadow-lg">
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-foreground">Balance Total</span>
                      <span className="text-2xl font-bold text-primary">$12,450</span>
                    </div>
                  </div>
                  <div className="bg-gradient-to-br from-primary to-secondary p-4 rounded-2xl text-white shadow-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <Sparkles className="w-4 h-4" />
                      <span className="text-xs font-bold">Recomendación IA</span>
                    </div>
                    <p className="text-xs">Ahorra $400 comprando en Mi Comisariato</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Phone shadow */}
            <div className="absolute inset-0 -z-10 bg-gradient-to-b from-primary/20 to-secondary/20 blur-3xl transform translate-y-8" />
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="container mx-auto px-4 py-16 md:py-24">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-5xl font-bold mb-4">Características que te ayudan a ahorrar</h2>
          <p className="text-xl text-foreground max-w-2xl mx-auto">
            Todo lo que necesitas para tomar control de tus finanzas
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 max-w-6xl mx-auto">
          <Card className="p-6 border-2 hover:border-primary transition-colors">
            <div className="w-12 h-12 rounded-2xl bg-primary/10 flex items-center justify-center mb-4">
              <Sparkles className="w-6 h-6 text-primary" />
            </div>
            <h3 className="text-xl font-bold mb-2">Recomendaciones IA</h3>
            <p className="text-foreground text-pretty">
              Gemini analiza tus gastos y te sugiere dónde puedes ahorrar más
            </p>
          </Card>

          <Card className="p-6 border-2 hover:border-secondary transition-colors">
            <div className="w-12 h-12 rounded-2xl bg-secondary/10 flex items-center justify-center mb-4">
              <TrendingUp className="w-6 h-6 text-secondary" />
            </div>
            <h3 className="text-xl font-bold mb-2">Chat IA Inteligente</h3>
            <p className="text-foreground text-pretty">
              Pregunta sobre ofertas y descuentos en Ecuador y recibe respuestas personalizadas
            </p>
          </Card>

          <Card className="p-6 border-2 hover:border-accent transition-colors">
            <div className="w-12 h-12 rounded-2xl bg-accent/10 flex items-center justify-center mb-4">
              <Target className="w-6 h-6 text-accent" />
            </div>
            <h3 className="text-xl font-bold mb-2">Metas de ahorro</h3>
            <p className="text-foreground text-pretty">
              Define objetivos y recibe un plan personalizado para alcanzarlos
            </p>
          </Card>

          <Card className="p-6 border-2 hover:border-success transition-colors">
            <div className="w-12 h-12 rounded-2xl bg-success/10 flex items-center justify-center mb-4">
              <Shield className="w-6 h-6 text-success" />
            </div>
            <h3 className="text-xl font-bold mb-2">100% Seguro</h3>
            <p className="text-foreground text-pretty">
              Tus datos están encriptados y protegidos con los más altos estándares
            </p>
          </Card>
        </div>
      </section>

      {/* How it works */}
      <section id="how-it-works" className="container mx-auto px-4 py-16 md:py-24 bg-surface/50 rounded-3xl">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-5xl font-bold mb-4">Cómo funciona</h2>
          <p className="text-xl text-foreground max-w-2xl mx-auto">Tres simples pasos para comenzar a ahorrar</p>
        </div>

        <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
          <div className="text-center space-y-4">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-primary to-primary-dark text-white text-2xl font-bold flex items-center justify-center mx-auto">
              1
            </div>
            <h3 className="text-xl font-bold">Regístrate gratis</h3>
            <p className="text-foreground text-pretty">Crea tu cuenta en segundos y configura tu perfil financiero</p>
          </div>

          <div className="text-center space-y-4">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-secondary to-primary text-white text-2xl font-bold flex items-center justify-center mx-auto">
              2
            </div>
            <h3 className="text-xl font-bold">La IA analiza</h3>
            <p className="text-foreground text-pretty">
              Gemini estudia tus patrones de gasto y encuentra oportunidades para ahorrar
            </p>
          </div>

          <div className="text-center space-y-4">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-accent to-secondary text-white text-2xl font-bold flex items-center justify-center mx-auto">
              3
            </div>
            <h3 className="text-xl font-bold">Ahorra más dinero</h3>
            <p className="text-foreground text-pretty">
              Recibe recomendaciones personalizadas de lugares con ofertas y alcanza tus metas
            </p>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="container mx-auto px-4 py-16 md:py-24">
        <Card className="p-8 md:p-12 bg-gradient-to-br from-primary via-secondary to-accent text-white border-0">
          <div className="max-w-3xl mx-auto text-center space-y-6">
            <h2 className="text-3xl md:text-5xl font-bold text-balance">Comienza a ahorrar hoy mismo</h2>
            <p className="text-xl text-white/90 text-pretty">
              Únete a miles de usuarios que ya están ahorrando más con AhorraMax
            </p>
            <Button
              asChild
              size="lg"
              className="rounded-full bg-white text-primary hover:bg-white/90 px-8 h-14 text-lg"
            >
              <Link href="/register">Crear cuenta gratis</Link>
            </Button>
          </div>
        </Card>
      </section>

      {/* Footer */}
      <footer className="border-t border-border py-8">
        <div className="container mx-auto px-4 text-center text-foreground">
          <p>&copy; 2025 AhorraMax. Todos los derechos reservados.</p>
        </div>
      </footer>
    </div>
  )
}
