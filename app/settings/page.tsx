"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { ArrowLeft, Globe, Palette, Bell, ToggleLeft, ToggleRight, Zap, DollarSign } from "lucide-react"

const THEMES = [
  { id: "default", name: "Verde Primario", colors: { primary: "#10b981", secondary: "#06b6d4" } },
  { id: "ocean", name: "Océano", colors: { primary: "#0ea5e9", secondary: "#06b6d4" } },
  { id: "sunset", name: "Atardecer", colors: { primary: "#f97316", secondary: "#ec4899" } },
  { id: "forest", name: "Bosque", colors: { primary: "#059669", secondary: "#0d9488" } },
  { id: "purple", name: "Púrpura", colors: { primary: "#7c3aed", secondary: "#a855f7" } },
  { id: "rose", name: "Rosa", colors: { primary: "#e11d48", secondary: "#f43f5e" } },
]

const LANGUAGES = [
  { code: "es", name: "Español", flag: "🇪🇨" },
  { code: "en", name: "English", flag: "🇺🇸" },
  { code: "pt", name: "Português", flag: "🇧🇷" },
  { code: "fr", name: "Français", flag: "🇫🇷" },
]

export default function SettingsPage() {
  const router = useRouter()
  const [language, setLanguage] = useState("es")
  const [theme, setTheme] = useState("default")
  const [enableRecommendations, setEnableRecommendations] = useState(true)
  const [recommendationFrequency, setRecommendationFrequency] = useState("8")
  const [enableStreakNotifications, setEnableStreakNotifications] = useState(true)
  const [enableDailyReminders, setEnableDailyReminders] = useState(true)

  const handleThemeChange = (themeId: string) => {
    setTheme(themeId)
    const selectedTheme = THEMES.find((t) => t.id === themeId)
    if (selectedTheme) {
      localStorage.setItem("theme", themeId)
      localStorage.setItem("themeColors", JSON.stringify(selectedTheme.colors))
      // Aquí se aplicaría el tema al documento
      document.documentElement.style.setProperty("--primary", selectedTheme.colors.primary)
      document.documentElement.style.setProperty("--secondary", selectedTheme.colors.secondary)
    }
  }

  const handleLanguageChange = (langCode: string) => {
    setLanguage(langCode)
    localStorage.setItem("language", langCode)
    // Aquí se aplicaría el idioma a la aplicación
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border bg-card sticky top-0 z-50 backdrop-blur-sm">
        <div className="container mx-auto px-4 py-4 flex items-center gap-4">
          <Button variant="ghost" size="icon" onClick={() => router.back()} className="rounded-xl hover:bg-primary/10">
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <h1 className="text-2xl font-bold text-foreground">Configuración</h1>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8 max-w-2xl space-y-6">
        {/* Lenguaje */}
        <Card className="p-6 border-2 border-primary/20">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center">
              <Globe className="w-6 h-6 text-primary" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-foreground">Idioma</h2>
              <p className="text-sm text-muted-foreground">Elige tu idioma preferido</p>
            </div>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            {LANGUAGES.map((lang) => (
              <Button
                key={lang.code}
                onClick={() => handleLanguageChange(lang.code)}
                className={`rounded-xl h-20 flex flex-col items-center gap-2 transition-all ${
                  language === lang.code
                    ? "bg-gradient-to-br from-primary to-secondary text-white border-2 border-primary"
                    : "bg-card border-2 border-border hover:border-primary/50"
                }`}
              >
                <span className="text-2xl">{lang.flag}</span>
                <span className="text-xs font-medium text-center">{lang.name}</span>
              </Button>
            ))}
          </div>
        </Card>

        {/* Temas */}
        <Card className="p-6 border-2 border-primary/20">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center">
              <Palette className="w-6 h-6 text-primary" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-foreground">Temas de Color</h2>
              <p className="text-sm text-muted-foreground">Personaliza la apariencia de AhorraMax</p>
            </div>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
            {THEMES.map((themeOption) => (
              <button
                key={themeOption.id}
                onClick={() => handleThemeChange(themeOption.id)}
                className={`rounded-2xl p-4 transition-all transform hover:scale-105 ${
                  theme === themeOption.id ? "ring-4 ring-offset-2 ring-primary scale-105" : ""
                }`}
              >
                <div className="space-y-2 mb-2">
                  <div className="flex gap-2">
                    <div className="w-8 h-8 rounded-lg" style={{ backgroundColor: themeOption.colors.primary }} />
                    <div className="w-8 h-8 rounded-lg" style={{ backgroundColor: themeOption.colors.secondary }} />
                  </div>
                </div>
                <p className="text-xs font-medium text-foreground text-left">{themeOption.name}</p>
              </button>
            ))}
          </div>
        </Card>

        {/* Recomendaciones */}
        <Card className="p-6 border-2 border-primary/20">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center">
              <Zap className="w-6 h-6 text-primary" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-foreground">Recomendaciones de IA</h2>
              <p className="text-sm text-muted-foreground">Controla cuándo recibes sugerencias</p>
            </div>
          </div>

          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 bg-background rounded-xl">
              <div>
                <p className="font-medium text-foreground">Activar Recomendaciones</p>
                <p className="text-sm text-muted-foreground">Recibe sugerencias personalizadas de ahorro</p>
              </div>
              <Button
                variant="ghost"
                size="icon"
                onClick={() => setEnableRecommendations(!enableRecommendations)}
                className="rounded-full"
              >
                {enableRecommendations ? (
                  <ToggleRight className="w-6 h-6 text-primary" />
                ) : (
                  <ToggleLeft className="w-6 h-6 text-muted-foreground" />
                )}
              </Button>
            </div>

            {enableRecommendations && (
              <div className="p-4 bg-background rounded-xl">
                <label className="block text-sm font-medium text-foreground mb-3">
                  Frecuencia de Recomendaciones (segundos)
                </label>
                <select
                  value={recommendationFrequency}
                  onChange={(e) => setRecommendationFrequency(e.target.value)}
                  className="w-full p-3 rounded-xl border-2 border-primary/20 bg-card focus:border-primary focus:outline-none"
                >
                  <option value="5">Cada 5 segundos (Muy frecuente)</option>
                  <option value="8">Cada 8 segundos (Recomendado)</option>
                  <option value="15">Cada 15 segundos (Normal)</option>
                  <option value="30">Cada 30 segundos (Poco frecuente)</option>
                  <option value="60">Cada 60 segundos (Raro)</option>
                </select>
              </div>
            )}
          </div>
        </Card>

        {/* Notificaciones */}
        <Card className="p-6 border-2 border-primary/20">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center">
              <Bell className="w-6 h-6 text-primary" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-foreground">Notificaciones</h2>
              <p className="text-sm text-muted-foreground">Gestiona tus preferencias de alertas</p>
            </div>
          </div>

          <div className="space-y-3">
            <div className="flex items-center justify-between p-4 bg-background rounded-xl">
              <div>
                <p className="font-medium text-foreground">Notificaciones de Racha</p>
                <p className="text-sm text-muted-foreground">Alertas cuando completes metas diarias</p>
              </div>
              <Button
                variant="ghost"
                size="icon"
                onClick={() => setEnableStreakNotifications(!enableStreakNotifications)}
                className="rounded-full"
              >
                {enableStreakNotifications ? (
                  <ToggleRight className="w-6 h-6 text-primary" />
                ) : (
                  <ToggleLeft className="w-6 h-6 text-muted-foreground" />
                )}
              </Button>
            </div>

            <div className="flex items-center justify-between p-4 bg-background rounded-xl">
              <div>
                <p className="font-medium text-foreground">Recordatorios Diarios</p>
                <p className="text-sm text-muted-foreground">Notificación a las 8:00 AM</p>
              </div>
              <Button
                variant="ghost"
                size="icon"
                onClick={() => setEnableDailyReminders(!enableDailyReminders)}
                className="rounded-full"
              >
                {enableDailyReminders ? (
                  <ToggleRight className="w-6 h-6 text-primary" />
                ) : (
                  <ToggleLeft className="w-6 h-6 text-muted-foreground" />
                )}
              </Button>
            </div>
          </div>
        </Card>

        {/* Información */}
        <Card className="p-6 border-2 border-primary/20 bg-gradient-to-br from-primary/5 to-secondary/5">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center">
              <DollarSign className="w-6 h-6 text-primary" />
            </div>
            <div>
              <h3 className="font-bold text-foreground mb-1">Acerca de AhorraMax</h3>
              <p className="text-sm text-muted-foreground mb-3">
                Tu asistente inteligente de finanzas personales. Ahorra más, gasta mejor, vive mejor.
              </p>
              <p className="text-xs text-muted-foreground">Versión 1.0.0 • Creado en Ecuador</p>
            </div>
          </div>
        </Card>
      </div>
    </div>
  )
}
