"use client"

import type React from "react"

import { useState } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card } from "@/components/ui/card"
import { Phone, Lock, User, Eye, EyeOff, ArrowLeft, Mail } from "lucide-react"

export default function RegisterPage() {
  const router = useRouter()
  const [name, setName] = useState("")
  const [email, setEmail] = useState("")
  const [phone, setPhone] = useState("")
  const [password, setPassword] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState("")

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setError("")

    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setError("Ingresa un email válido")
      return
    }

    if (phone.length !== 10) {
      setError("El celular debe tener 10 dígitos")
      return
    }

    if (password.length < 8) {
      setError("La contraseña debe tener mínimo 8 caracteres")
      return
    }
    if (!/[A-Z]/.test(password)) {
      setError("La contraseña debe tener al menos una mayúscula")
      return
    }
    if (!/[a-z]/.test(password)) {
      setError("La contraseña debe tener al menos una minúscula")
      return
    }
    if (!/[0-9]/.test(password)) {
      setError("La contraseña debe tener al menos un número")
      return
    }

    if (name && email && phone && password) {
      localStorage.setItem("user", JSON.stringify({ phone, name, email }))
      localStorage.removeItem("hasSeenTutorial")
      router.push("/splash")
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary/20 via-secondary/10 to-accent/20 flex items-center justify-center p-4">
      <Button asChild variant="outline" size="icon" className="fixed top-4 left-4 rounded-xl z-50 bg-transparent">
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
            Únete a AhorraMax
          </h1>
          <p className="text-muted-foreground">Crea tu cuenta y comienza a ahorrar</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          {error && (
            <div className="p-4 rounded-xl bg-destructive/10 border-2 border-destructive/20 text-destructive text-sm font-medium text-center">
              {error}
            </div>
          )}

          <div className="space-y-2">
            <Label htmlFor="name" className="font-bold text-foreground">
              Nombre completo
            </Label>
            <div className="relative">
              <User className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
              <Input
                id="name"
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Tu nombre"
                className="pl-10 py-6 rounded-xl border-2"
                required
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="email" className="font-bold text-foreground">
              Email
            </Label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="tu@email.com"
                className="pl-10 py-6 rounded-xl border-2"
                required
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="phone" className="font-bold text-foreground">
              Número de Celular
            </Label>
            <div className="relative">
              <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
              <Input
                id="phone"
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value.replace(/\D/g, "").slice(0, 10))}
                placeholder="0987654321"
                className="pl-10 py-6 rounded-xl border-2 text-lg font-medium"
                required
                maxLength={10}
              />
            </div>
            <p className="text-xs text-muted-foreground">10 dígitos (Ecuador)</p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="password" className="font-bold text-foreground">
              Contraseña segura
            </Label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
              <Input
                id="password"
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="pl-10 pr-10 py-6 rounded-xl border-2"
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
            <p className="text-xs text-muted-foreground">Mínimo 8 caracteres, mayúsculas, minúsculas y números</p>
          </div>

          <Button
            type="submit"
            className="w-full py-7 rounded-2xl font-bold text-xl bg-gradient-to-r from-primary via-secondary to-primary text-white hover:scale-[1.02] hover:shadow-xl transition-all duration-300 shadow-lg"
          >
            Crear Cuenta
          </Button>
        </form>

        <div className="mt-8 pt-6 border-t border-border">
          <div className="text-center space-y-3">
            <p className="text-sm text-muted-foreground">¿Ya tienes cuenta?</p>
            <Button
              asChild
              variant="outline"
              className="w-full py-6 rounded-xl font-bold text-lg border-2 border-primary/30 hover:bg-primary/10 hover:border-primary transition-all bg-transparent"
            >
              <Link href="/login">Iniciar Sesión</Link>
            </Button>
          </div>
        </div>
      </Card>
    </div>
  )
}
