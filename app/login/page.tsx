"use client"

import type React from "react"

import { useState } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card } from "@/components/ui/card"
import { Mail, Lock, Eye, EyeOff, ArrowLeft } from "lucide-react"

export default function LoginPage() {
  const router = useRouter()
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState("")
  const [showForgotPassword, setShowForgotPassword] = useState(false)
  const [resetEmail, setResetEmail] = useState("")
  const [resetMessage, setResetMessage] = useState("")

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setError("")

    if (!email.includes("@")) {
      setError("Por favor ingresa un correo válido")
      return
    }

    if (password.length < 8) {
      setError("La contraseña debe tener al menos 8 caracteres")
      return
    }

    if (email && password) {
      localStorage.setItem("user", JSON.stringify({ email, name: "Usuario" }))
      router.push("/splash")
    }
  }

  const handleForgotPassword = async (e: React.FormEvent) => {
    e.preventDefault()
    setResetMessage("")

    if (!resetEmail.includes("@")) {
      setResetMessage("Por favor ingresa un correo válido")
      return
    }

    // Simular envío de email
    setTimeout(() => {
      setResetMessage(
        `Se ha enviado un correo de recuperación a ${resetEmail}. Por favor revisa tu bandeja de entrada.`,
      )
    }, 1000)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/20 via-secondary/10 to-accent/20 flex items-center justify-center p-4">
      <Button asChild variant="outline" size="icon" className="fixed top-4 left-4 rounded-xl z-50 bg-card">
        <Link href="/">
          <ArrowLeft className="w-5 h-5" />
        </Link>
      </Button>

      <Card className="w-full max-w-md p-8 bg-card/95 backdrop-blur-sm border-2">
        <div className="text-center mb-8">
          <div className="w-20 h-20 mx-auto mb-4 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center text-4xl font-bold text-white shadow-xl animate-bounce">
            $
          </div>
          <h1 className="text-3xl font-bold mb-2 bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
            AhorraMax
          </h1>
          <p className="text-black">Inicia sesión para continuar ahorrando</p>
        </div>

        {!showForgotPassword ? (
          <form onSubmit={handleSubmit} className="space-y-5">
            {error && (
              <div className="p-4 rounded-xl bg-destructive/10 border-2 border-destructive/20 text-destructive text-sm font-medium text-center">
                {error}
              </div>
            )}

            <div className="space-y-2">
              <Label htmlFor="email" className="font-bold text-black">
                Correo Electrónico
              </Label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                <Input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="tucorreo@ejemplo.com"
                  className="pl-10 py-6 rounded-xl border-2 text-lg font-medium text-black"
                  required
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="password" className="font-bold text-black">
                Contraseña
              </Label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="pl-10 pr-10 py-6 rounded-xl border-2 text-black"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
            </div>

            <div className="text-right">
              <button
                type="button"
                onClick={() => setShowForgotPassword(true)}
                className="text-sm text-primary hover:underline font-medium"
              >
                ¿Olvidaste tu contraseña?
              </button>
            </div>

            <Button
              type="submit"
              className="w-full py-7 rounded-2xl font-bold text-xl bg-gradient-to-r from-primary via-secondary to-primary text-white hover:scale-[1.02] hover:shadow-xl transition-all duration-300 shadow-lg"
            >
              Iniciar Sesión
            </Button>
          </form>
        ) : (
          <div className="space-y-5">
            <div className="text-center mb-4">
              <h2 className="text-xl font-bold text-black mb-2">Recuperar Contraseña</h2>
              <p className="text-sm text-muted-foreground">
                Te enviaremos un correo con instrucciones para restablecer tu contraseña
              </p>
            </div>

            {resetMessage && (
              <div
                className={`p-4 rounded-xl border-2 text-sm font-medium ${
                  resetMessage.includes("enviado")
                    ? "bg-primary/10 border-primary/20 text-foreground"
                    : "bg-destructive/10 border-destructive/20 text-destructive"
                }`}
              >
                {resetMessage}
              </div>
            )}

            <form onSubmit={handleForgotPassword} className="space-y-5">
              <div className="space-y-2">
                <Label htmlFor="reset-email" className="font-bold text-black">
                  Correo Electrónico
                </Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
                  <Input
                    id="reset-email"
                    type="email"
                    value={resetEmail}
                    onChange={(e) => setResetEmail(e.target.value)}
                    placeholder="tucorreo@ejemplo.com"
                    className="pl-10 py-6 rounded-xl border-2 text-lg font-medium text-black"
                    required
                  />
                </div>
              </div>

              <Button
                type="submit"
                className="w-full py-7 rounded-2xl font-bold text-xl bg-gradient-to-r from-primary via-secondary to-primary text-white hover:scale-[1.02] hover:shadow-xl transition-all duration-300 shadow-lg"
              >
                Enviar Correo de Recuperación
              </Button>

              <Button
                type="button"
                variant="outline"
                onClick={() => {
                  setShowForgotPassword(false)
                  setResetMessage("")
                  setResetEmail("")
                }}
                className="w-full py-6 rounded-xl font-bold text-lg border-2"
              >
                Volver al Login
              </Button>
            </form>
          </div>
        )}

        {!showForgotPassword && (
          <div className="mt-8 pt-6 border-t border-border">
            <div className="text-center space-y-3">
              <p className="text-sm text-muted-foreground">¿No tienes cuenta?</p>
              <Button
                asChild
                variant="outline"
                className="w-full py-6 rounded-xl font-bold text-lg border-2 border-primary/30 hover:bg-primary/10 hover:border-primary transition-all bg-transparent"
              >
                <Link href="/register">Crear Cuenta Nueva</Link>
              </Button>
            </div>
          </div>
        )}
      </Card>
    </div>
  )
}
