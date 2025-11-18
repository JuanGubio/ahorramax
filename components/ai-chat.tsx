"use client"

import { useState, useRef, useEffect } from "react"
import { Card } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { MessageCircle, X, Send, MapPin } from "lucide-react"

interface Message {
  id: string
  text: string
  sender: "user" | "ai"
  timestamp: Date
  imageUrl?: string
  location?: string
}

interface AIChatProps {
  initialCategory?: string | null
}

export function AIChat({ initialCategory }: AIChatProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [messages, setMessages] = useState<Message[]>([
    {
      id: "1",
      text: "Hola! Soy tu asistente financiero con IA. Puedo ayudarte a encontrar las mejores ofertas en Ecuador, lugares para ahorrar y consejos personalizados. ¿En qué te puedo ayudar hoy?",
      sender: "ai",
      timestamp: new Date(),
    },
  ])
  const [input, setInput] = useState("")
  const [isTyping, setIsTyping] = useState(false)
  const [uploadedImage, setUploadedImage] = useState<string | null>(null)
  const [searchQuery, setSearchQuery] = useState("")
  const [userLocation, setUserLocation] = useState<{ lat: number; lon: number } | null>(null)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" })
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  useEffect(() => {
    if (isOpen && !userLocation) {
      if ("geolocation" in navigator) {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            setUserLocation({
              lat: position.coords.latitude,
              lon: position.coords.longitude,
            })
          },
          (error) => {
            console.log("Ubicación no disponible:", error)
          },
        )
      }
    }
  }, [isOpen, userLocation])

  useEffect(() => {
    if (initialCategory) {
      setIsOpen(true)
      const filterBy = sessionStorage.getItem("chatFilterBy")
      const establishment = filterBy ? `de ${filterBy}` : ""

      const categoryMessages: Record<string, string> = {
        comida: `Quiero ver las ofertas ${establishment} disponibles ahora en Ecuador, especialmente combos y descuentos`,
        transporte: "Necesito información sobre transporte público y opciones económicas",
        compras: "Quiero saber dónde hay descuentos para compras",
      }

      const message = categoryMessages[initialCategory] || `Busco ofertas de ${initialCategory}`
      setInput(message)
      setTimeout(() => handleSend(message), 500)

      // Limpiar el filtro después de usarlo
      sessionStorage.removeItem("chatFilterBy")
    }
  }, [initialCategory])

  const handleSend = async (customMessage?: string, imageData?: string) => {
    const messageToSend = customMessage || input
    if (!messageToSend.trim()) return

    const userMessage: Message = {
      id: Date.now().toString(),
      text: messageToSend,
      sender: "user",
      timestamp: new Date(),
      imageUrl: imageData || uploadedImage || undefined,
    }

    setMessages((prev) => [...prev, userMessage])
    setInput("")
    setUploadedImage(null)
    setIsTyping(true)

    setTimeout(async () => {
      try {
        const response = await fetch("/api/ai-chat", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            message: messageToSend,
            hasImage: !!(imageData || uploadedImage),
            userLocation: userLocation, // Enviar coordenadas del usuario
          }),
        })

        const data = await response.json()

        const aiMessage: Message = {
          id: (Date.now() + 1).toString(),
          text: data.response,
          sender: "ai",
          timestamp: new Date(),
          imageUrl: data.imageUrl,
          location: data.location,
        }

        setMessages((prev) => [...prev, aiMessage])
      } catch (error) {
        console.error("Error:", error)
        const errorMessage: Message = {
          id: (Date.now() + 1).toString(),
          text: "Lo siento, hubo un error. Por favor intenta de nuevo.",
          sender: "ai",
          timestamp: new Date(),
        }
        setMessages((prev) => [...prev, errorMessage])
      } finally {
        setIsTyping(false)
      }
    }, 1500)
  }

  return (
    <>
      {!isOpen && (
        <Button
          onClick={() => setIsOpen(true)}
          className="fixed bottom-6 right-6 w-16 h-16 rounded-full bg-gradient-to-br from-primary to-secondary text-white shadow-2xl hover:scale-110 transition-transform z-40"
          size="icon"
        >
          <MessageCircle className="w-7 h-7" />
        </Button>
      )}

      {isOpen && (
        <Card className="fixed bottom-6 right-6 w-[90vw] sm:w-96 h-[600px] shadow-2xl z-50 flex flex-col border-2 border-primary/20 animate-in slide-in-from-bottom-5 duration-300">
          <div className="p-4 bg-gradient-to-br from-primary to-secondary text-white rounded-t-xl flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center text-lg font-bold">
                $
              </div>
              <div>
                <h3 className="font-bold">Chat IA AhorraMax</h3>
                <p className="text-xs text-white/80">En línea</p>
              </div>
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setIsOpen(false)}
              className="text-white hover:bg-white/20 rounded-full"
            >
              <X className="w-5 h-5" />
            </Button>
          </div>

          <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-background/50">
            {messages.map((message) => (
              <div key={message.id} className={`flex ${message.sender === "user" ? "justify-end" : "justify-start"}`}>
                <div
                  className={`max-w-[80%] p-3 rounded-2xl ${
                    message.sender === "user"
                      ? "bg-gradient-to-br from-primary to-secondary text-white rounded-br-sm"
                      : "bg-card border-2 border-primary/20 text-foreground rounded-bl-sm"
                  }`}
                >
                  {message.imageUrl && (
                    <div className="mb-2 rounded-lg overflow-hidden">
                      <img src={message.imageUrl || "/placeholder.svg"} alt="Oferta" className="w-full h-auto" />
                    </div>
                  )}
                  <p className="text-sm text-pretty leading-relaxed whitespace-pre-line">{message.text}</p>
                  {message.location && (
                    <div className="mt-2 flex items-center gap-1 text-xs opacity-80">
                      <MapPin className="w-3 h-3" />
                      <span>{message.location}</span>
                    </div>
                  )}
                  <p
                    className={`text-xs mt-1 ${message.sender === "user" ? "text-white/70" : "text-muted-foreground"}`}
                  >
                    {message.timestamp.toLocaleTimeString("es-EC", {
                      hour: "2-digit",
                      minute: "2-digit",
                    })}
                  </p>
                </div>
              </div>
            ))}
            {isTyping && (
              <div className="flex justify-start">
                <div className="bg-card border-2 border-primary/20 p-3 rounded-2xl rounded-bl-sm">
                  <div className="flex gap-1">
                    <div className="w-2 h-2 bg-primary rounded-full animate-bounce" style={{ animationDelay: "0ms" }} />
                    <div
                      className="w-2 h-2 bg-primary rounded-full animate-bounce"
                      style={{ animationDelay: "150ms" }}
                    />
                    <div
                      className="w-2 h-2 bg-primary rounded-full animate-bounce"
                      style={{ animationDelay: "300ms" }}
                    />
                  </div>
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>

          <div className="p-4 border-t border-border bg-card">
            <div className="space-y-3 mb-3">
              <Input
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Escribe lo que buscas (ej: juguetes, zapatos)..."
                className="rounded-xl border-2 border-primary/20 focus:border-primary"
                disabled={isTyping}
                onKeyPress={(e) => {
                  if (e.key === "Enter" && !e.shiftKey) {
                    e.preventDefault()
                    handleSend(searchQuery)
                    setSearchQuery("")
                  }
                }}
              />

              <div className="flex gap-2">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  className="hidden"
                  onChange={(e) => {
                    const file = e.target.files?.[0]
                    if (file) {
                      const reader = new FileReader()
                      reader.onload = () => {
                        const imageDataUrl = reader.result as string
                        setUploadedImage(imageDataUrl)
                        const imageQuery =
                          "Analiza esta imagen y dime dónde puedo encontrar este producto con el mejor precio y descuentos en Ecuador"
                        setInput(imageQuery)
                        setSearchQuery(imageQuery)
                      }
                      reader.readAsDataURL(file)
                    }
                  }}
                />
                <Button
                  variant="outline"
                  size="sm"
                  className="rounded-xl text-xs bg-transparent flex-1"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={isTyping}
                >
                  📸 Subir Foto
                </Button>
                <Button
                  type="button"
                  size="sm"
                  className="rounded-xl bg-gradient-to-br from-primary to-secondary text-white flex-1"
                  disabled={isTyping || (!input.trim() && !searchQuery.trim())}
                  onClick={() => {
                    const messageToSend = searchQuery || input
                    handleSend(messageToSend)
                    setSearchQuery("")
                  }}
                >
                  <Send className="w-4 h-4 mr-1" />
                  Enviar
                </Button>
              </div>

              {uploadedImage && (
                <div className="relative rounded-lg overflow-hidden border-2 border-primary">
                  <img
                    src={uploadedImage || "/placeholder.svg"}
                    alt="Imagen subida"
                    className="w-full h-32 object-cover"
                  />
                  <Button
                    size="icon"
                    variant="destructive"
                    className="absolute top-2 right-2 w-6 h-6 rounded-full"
                    onClick={() => {
                      setUploadedImage(null)
                      setInput("")
                    }}
                  >
                    <X className="w-3 h-3" />
                  </Button>
                </div>
              )}
            </div>
          </div>
        </Card>
      )}
    </>
  )
}
