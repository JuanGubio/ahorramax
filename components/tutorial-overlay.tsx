"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { X, ArrowRight, Sparkles, CheckCircle2 } from "lucide-react"
import { debounce } from "lodash"

interface TutorialOverlayProps {
  onComplete: () => void
}

const tutorialSteps = [
  {
    id: "welcome",
    title: "¡Bienvenido a AhorraMax!",
    description: "Tu asistente inteligente para ahorrar dinero",
    detail:
      "AhorraMax es una app que te ayuda a gestionar tus finanzas, recibir recomendaciones personalizadas de IA sobre dónde gastar menos, encontrar ofertas y descuentos en Ecuador, y crear metas de ahorro. Vamos a hacer un recorrido rápido.",
    interactive: false,
    pointerTarget: null,
  },
  {
    id: "click-add-money",
    title: "Paso 1: Agregar dinero",
    description: "Haz clic en el botón + de Balance Total",
    detail: "Primero, agrega dinero a tu balance. Haz clic en el botón marcado.",
    interactive: true,
    action: "open-add-money",
    pointerTarget: "balance-add-btn",
    waitForDialog: true,
  },
  {
    id: "enter-amount",
    title: "Paso 2: Ingresa el monto",
    description: "Ingresa 100$", // cambiar de "Escribe 100" a "Ingresa 100$"
    detail: "Ingresa $100 para practicar.",
    interactive: true,
    action: "enter-amount",
    pointerTarget: "add-money-input",
    waitForDialog: true,
  },
  {
    id: "click-add-button",
    title: "Paso 3: Guardar el dinero",
    description: "Haz clic en Agregar",
    detail: "Presiona el botón verde marcado.",
    interactive: true,
    action: "add-money",
    pointerTarget: "add-money-submit",
    waitForDialog: true,
  },
  {
    id: "click-add-expense",
    title: "Paso 4: Agregar un gasto",
    description: "Haz clic en Agregar Gasto",
    detail: "Ahora vamos a registrar un gasto.",
    interactive: true,
    action: "open-add-expense",
    pointerTarget: "add-expense-btn",
    waitForDialog: true,
  },
  {
    id: "select-category",
    title: "Paso 5: Selecciona categoría",
    description: "Elige Restaurantes",
    detail: "Selecciona la categoría de tu gasto.",
    interactive: true,
    action: "select-category",
    pointerTarget: "category-restaurantes",
    waitForDialog: true,
  },
  {
    id: "enter-expense-amount",
    title: "Paso 6: Ingresa el monto",
    description: "Ingresa 20$", // cambiar de "Escribe 20" a "Ingresa 20$"
    detail: "Ingresa $20 como ejemplo.",
    interactive: true,
    action: "enter-expense-amount",
    pointerTarget: "expense-amount-input",
    waitForDialog: true,
  },
  {
    id: "enter-description",
    title: "Paso 7: Agrega descripción",
    description: "Escribe Almuerzo",
    detail: "Describe tu gasto.",
    interactive: true,
    action: "enter-description",
    pointerTarget: "expense-description-input",
    waitForDialog: true,
  },
  {
    id: "save-expense",
    title: "Paso 8: Guardar el gasto",
    description: "Haz clic en Guardar Gasto",
    detail: "Presiona el botón marcado.",
    interactive: true,
    action: "add-expense",
    pointerTarget: "save-expense-btn",
    waitForDialog: true,
  },
  {
    id: "features",
    title: "¡Excelente!",
    description: "Has completado el tutorial",
    detail:
      "Ahora puedes ver estadísticas, crear metas de ahorro, chatear con la IA para encontrar ofertas, recibir recomendaciones personalizadas y mucho más. ¡Empieza a ahorrar!",
    interactive: false,
    pointerTarget: null,
  },
]

const validateAction = (actionType: string, elementId: string): boolean => {
  switch (actionType) {
    case "enter-amount": {
      const input = document.getElementById(elementId) as HTMLInputElement
      return input && input.value !== "" && Number.parseFloat(input.value) > 0
    }
    case "enter-expense-amount": {
      const input = document.getElementById(elementId) as HTMLInputElement
      return input && input.value !== "" && Number.parseFloat(input.value) > 0
    }
    case "enter-description": {
      const input = document.getElementById(elementId) as HTMLInputElement
      return input && input.value.trim().length >= 3
    }
    case "select-category": {
      const element = document.getElementById(elementId)
      return element && element.getAttribute("data-selected") === "true"
    }
    default:
      return true
  }
}

export function TutorialOverlay({ onComplete }: TutorialOverlayProps) {
  const [currentStep, setCurrentStep] = useState(0)
  const [isWaitingForAction, setIsWaitingForAction] = useState(false)
  const [showFinalScreen, setShowFinalScreen] = useState(false)
  const [spotlightRect, setSpotlightRect] = useState<DOMRect | null>(null)
  const [pointerPosition, setPointerPosition] = useState<{ x: number; y: number } | null>(null)

  const currentStepData = tutorialSteps[currentStep]

  useEffect(() => {
    console.log("[v0] Tutorial - currentStep:", currentStep, "isWaitingForAction:", isWaitingForAction)
    console.log("[v0] Tutorial - currentStepData:", currentStepData)

    const updatePositions = () => {
      const element = document.getElementById(currentStepData.pointerTarget!)
      if (element) {
        const rect = element.getBoundingClientRect()
        setSpotlightRect(rect)
        setPointerPosition({
          x: rect.left - 60,
          y: rect.top + rect.height / 2 - 25,
        })
      }
    }

    updatePositions()
    const interval = setInterval(updatePositions, 200)
    return () => clearInterval(interval)
  }, [currentStep, currentStepData.pointerTarget, currentStepData])

  useEffect(() => {
    if (!isWaitingForAction || !currentStepData.pointerTarget) return

    const element = document.getElementById(currentStepData.pointerTarget!)
    if (!element) return

    const currentAction = currentStepData.action
    const currentPointerTarget = currentStepData.pointerTarget

    const handleAction = debounce(() => {
      if (validateAction(currentAction!, currentPointerTarget!)) {
        console.log("[v0] Tutorial - Acción completada:", currentAction)
        setTimeout(() => {
          if (currentStep < tutorialSteps.length - 1) {
            const nextStep = tutorialSteps[currentStep + 1]
            console.log("[v0] Tutorial - Avanzando al paso:", nextStep.id)
            setCurrentStep(currentStep + 1)
            setIsWaitingForAction(nextStep.interactive)
          } else {
            setShowFinalScreen(true)
          }
        }, 300)
      }
    }, 100) // reducir debounce de 300ms a 100ms para mayor responsividad

    if (currentAction?.includes("enter")) {
      element.addEventListener("input", handleAction) // agregar input en tiempo real
      element.addEventListener("change", handleAction)
      element.addEventListener("blur", handleAction)
    } else {
      element.addEventListener("click", handleAction)
    }

    return () => {
      if (currentAction?.includes("enter")) {
        element.removeEventListener("input", handleAction)
        element.removeEventListener("change", handleAction)
        element.removeEventListener("blur", handleAction)
      } else {
        element.removeEventListener("click", handleAction)
      }
    }
  }, [isWaitingForAction, currentStep, currentStepData.action, currentStepData.pointerTarget])

  const handleNext = () => {
    if (currentStepData.interactive) {
      setIsWaitingForAction(true)
      return
    }

    if (currentStep < tutorialSteps.length - 1) {
      setCurrentStep(currentStep + 1)
      const nextStep = tutorialSteps[currentStep + 1]
      if (!nextStep.interactive) {
        setIsWaitingForAction(false)
      }
    } else {
      setShowFinalScreen(true)
    }
  }

  const handleCompleteFinal = () => {
    localStorage.setItem("hasSeenTutorial", "true")
    onComplete()
  }

  const handleSkip = () => {
    if (confirm("¿Seguro que quieres saltar el tutorial?")) {
      setShowFinalScreen(true)
    }
  }

  if (showFinalScreen) {
    return (
      <div className="fixed inset-0 bg-gradient-to-br from-primary via-secondary to-accent z-[100] flex flex-col items-center justify-center animate-in fade-in duration-500">
        <div className="text-center space-y-8 animate-in zoom-in duration-700">
          <div className="w-32 h-32 mx-auto rounded-full bg-white/20 backdrop-blur-xl flex items-center justify-center animate-bounce">
            <div className="text-6xl font-bold text-white">$</div>
          </div>

          <div className="space-y-3">
            <h1 className="text-5xl font-bold text-white drop-shadow-lg">Bienvenido a AhorraMax</h1>
            <p className="text-xl text-white/90">Tu viaje al ahorro inteligente comienza ahora</p>
          </div>

          <div className="flex items-center justify-center gap-2 text-white/80">
            <CheckCircle2 className="w-5 h-5" />
            <span>Tutorial completado exitosamente</span>
          </div>

          <Button
            onClick={handleCompleteFinal}
            size="lg"
            className="rounded-full bg-white text-primary hover:bg-white/90 px-8 py-6 text-lg font-bold shadow-2xl hover:scale-105 transition-transform"
          >
            Empezar a Ahorrar
            <ArrowRight className="w-5 h-5 ml-2" />
          </Button>
        </div>
      </div>
    )
  }

  if (isWaitingForAction) {
    return (
      <>
        <div className="fixed inset-0 z-[100]" style={{ pointerEvents: "none" }}>
          <svg width="100%" height="100%" className="absolute inset-0 pointer-events-none">
            <defs>
              <mask id="spotlight-mask">
                <rect x="0" y="0" width="100%" height="100%" fill="white" />
                {spotlightRect && (
                  <rect
                    x={spotlightRect.x - 12}
                    y={spotlightRect.y - 12}
                    width={spotlightRect.width + 24}
                    height={spotlightRect.height + 24}
                    rx="16"
                    fill="black"
                  />
                )}
              </mask>
            </defs>
            <rect x="0" y="0" width="100%" height="100%" fill="rgba(0,0,0,0.85)" mask="url(#spotlight-mask)" />
          </svg>
        </div>

        {spotlightRect && (
          <div
            className="fixed z-[101] rounded-2xl border-4 border-primary pointer-events-none animate-pulse"
            style={{
              left: spotlightRect.x - 12,
              top: spotlightRect.y - 12,
              width: spotlightRect.width + 24,
              height: spotlightRect.height + 24,
              boxShadow: "0 0 0 8px rgba(34, 197, 94, 0.3), 0 0 30px 12px rgba(34, 197, 94, 0.5)",
            }}
          />
        )}

        {pointerPosition && (
          <div
            className="fixed z-[103] pointer-events-none text-4xl sm:text-5xl md:text-6xl" // agregar responsive text size
            style={{
              left: pointerPosition.x,
              top: pointerPosition.y,
            }}
          >
            <div className="drop-shadow-2xl animate-bounce">👉</div>
          </div>
        )}

        {spotlightRect && (
          <div
            className="fixed z-[102] animate-in fade-in slide-in-from-bottom-5 duration-500 pointer-events-none px-2 sm:px-4 md:px-6" // agregar padding responsive
            style={{
              left: spotlightRect.x + spotlightRect.width / 2,
              top: spotlightRect.y + spotlightRect.height + 24,
              transform: "translateX(-50%)",
            }}
          >
            <div className="bg-primary text-white px-4 sm:px-6 py-2 sm:py-3 rounded-2xl shadow-2xl max-w-xs text-center font-bold text-sm sm:text-base md:text-lg border-2 border-white/20">
              {" "}
              {/* agregar responsive font y padding */}
              {currentStepData.description}
            </div>
          </div>
        )}
      </>
    )
  }

  return (
    <>
      <div className="fixed inset-0 bg-black/80 z-[100]" />

      <div className="fixed inset-x-0 bottom-0 z-[103] flex items-end justify-center p-2 sm:p-4 md:p-6">
        {" "}
        {/* agregar padding responsive */}
        <Card className="max-w-2xl w-full p-4 sm:p-6 animate-in slide-in-from-bottom-10 duration-500 bg-card border-2 border-primary shadow-2xl">
          {" "}
          {/* agregar padding responsive */}
          <div className="flex flex-col sm:flex-row items-start justify-between gap-3 sm:gap-4 mb-4">
            {" "}
            {/* cambiar a flex-col en mobile */}
            <div className="flex-1 min-w-0">
              {" "}
              {/* agregar min-w-0 para evitar overflow */}
              <div className="flex items-center gap-2 sm:gap-3 mb-3">
                <div className="w-10 sm:w-12 h-10 sm:h-12 rounded-full bg-gradient-to-br from-primary via-secondary to-accent flex items-center justify-center shadow-lg flex-shrink-0">
                  {" "}
                  {/* agregar flex-shrink-0 */}
                  <Sparkles className="w-5 sm:w-6 h-5 sm:h-6 text-white" /> {/* responsive icon size */}
                </div>
                <h3 className="text-lg sm:text-xl font-bold text-foreground text-balance line-clamp-2">
                  {" "}
                  {/* agregar text size responsive y line-clamp */}
                  {currentStepData.title}
                </h3>
              </div>
              <div className="space-y-2 sm:space-y-3">
                <p className="text-foreground font-medium text-pretty leading-relaxed text-sm sm:text-base">
                  {currentStepData.description}
                </p>{" "}
                {/* responsive font size */}
                <p className="text-foreground text-pretty leading-relaxed text-xs sm:text-sm">
                  {currentStepData.detail}
                </p>{" "}
                {/* responsive font size */}
              </div>
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={handleSkip}
              className="rounded-full hover:bg-destructive/10 hover:text-destructive -mt-1 -mr-1 flex-shrink-0" // agregar flex-shrink-0
            >
              <X className="w-4 sm:w-5 h-4 sm:h-5" /> {/* responsive icon size */}
            </Button>
          </div>
          <div className="flex items-center gap-1 sm:gap-2 mb-4 sm:mb-6">
            {" "}
            {/* responsive gap */}
            {tutorialSteps.map((_, index) => (
              <div
                key={index}
                className={`h-1.5 sm:h-2 flex-1 rounded-full transition-all duration-300 ${
                  index <= currentStep ? "bg-gradient-to-r from-primary to-secondary" : "bg-muted"
                }`}
              />
            ))}
          </div>
          <div className="flex flex-col sm:flex-row items-center justify-between gap-2 sm:gap-3">
            {" "}
            {/* cambiar a flex-col en mobile */}
            <Button
              variant="outline"
              onClick={handleSkip}
              className="rounded-xl bg-transparent w-full sm:w-auto text-sm sm:text-base"
            >
              {" "}
              {/* fullwidth en mobile */}
              Saltar Tutorial
            </Button>
            <Button
              onClick={handleNext}
              className="rounded-xl bg-gradient-to-r from-primary via-secondary to-accent text-white font-bold px-4 sm:px-6 py-2 sm:py-2 hover:scale-[1.02] transition-transform w-full sm:w-auto text-sm sm:text-base" // responsive padding y fullwidth en mobile
            >
              {currentStepData.interactive
                ? "Entendido"
                : currentStep < tutorialSteps.length - 1
                  ? "Siguiente"
                  : "Finalizar"}
              <ArrowRight className="w-4 h-4 ml-2" />
            </Button>
          </div>
        </Card>
      </div>
    </>
  )
}

export default TutorialOverlay
