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
    <div className="min-h-screen bg-gradient-to-br from-green-100 to-white flex items-center justify-center p-4">
      <Button asChild variant="outline" size="icon" className="fixed top-4 left-4 rounded-xl z-50 bg-transparent">
        <Link href="/">
          <ArrowLeft className="w-5 h-5" />
        </Link>
      </Button>

      <div className="bg-white p-10 rounded-3xl shadow-lg w-full max-w-md text-center">
        <div className="w-20 h-20 bg-green-500 rounded-full flex items-center justify-center mx-auto mb-4">
          <span className="text-white text-3xl font-bold">$</span>
        </div>

        <h1 className="text-green-700 text-2xl font-semibold mb-2">Únete a AhorraMax</h1>
        <p className="text-gray-500 mb-8">Crea tu cuenta y comienza a ahorrar</p>

        <form onSubmit={handleSubmit} className="space-y-5">
          {error && (
            <div className="p-4 rounded-xl bg-red-50 border-2 border-red-200 text-red-600 text-sm font-medium text-center">
              {error}
            </div>
          )}

          <div className="text-left">
            <label htmlFor="name" className="block mb-2 text-gray-800 font-semibold text-sm">Nombre completo</label>
            <div className="relative">
              <User className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <Input
                id="name"
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Tu nombre"
                className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-xl text-black"
                required
              />
            </div>
          </div>

          <div className="text-left">
            <label htmlFor="email" className="block mb-2 text-gray-800 font-semibold text-sm">Email</label>
            <div className="relative">
              <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="tu@email.com"
                className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-xl text-black"
                required
              />
            </div>
          </div>

          <div className="text-left">
            <label htmlFor="phone" className="block mb-2 text-gray-800 font-semibold text-sm">Número de Celular</label>
            <div className="relative">
              <Phone className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <Input
                id="phone"
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value.replace(/\D/g, "").slice(0, 10))}
                placeholder="0987654321"
                className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-xl text-black"
                required
                maxLength={10}
              />
            </div>
            <p className="text-xs text-gray-500 mt-1">10 dígitos (Ecuador)</p>
          </div>

          <div className="text-left">
            <label htmlFor="password" className="block mb-2 text-gray-800 font-semibold text-sm">Contraseña segura</label>
            <div className="relative">
              <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <Input
                id="password"
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-12 pr-12 py-3 border border-gray-300 rounded-xl text-black"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
            <p className="text-xs text-gray-500 mt-1">Mínimo 8 caracteres, mayúsculas, minúsculas y números</p>
          </div>

          <Button
            type="submit"
            className="w-full py-3 bg-gradient-to-r from-green-400 to-green-500 text-white rounded-xl font-semibold hover:opacity-90 transition-all shadow-md"
          >
            Crear Cuenta
          </Button>
        </form>

        <div className="mt-8 flex items-center text-gray-500">
          <div className="flex-1 border-t border-gray-300"></div>
          <span className="px-4 text-sm">¿Ya tienes cuenta?</span>
          <div className="flex-1 border-t border-gray-300"></div>
        </div>

        <Button
          asChild
          variant="outline"
          className="w-full py-3 mt-4 bg-white text-green-500 border-2 border-green-500 rounded-xl font-semibold hover:bg-green-50 transition-all"
        >
          <Link href="/login">Iniciar Sesión</Link>
        </Button>
      </div>
    </div>
  )
}
