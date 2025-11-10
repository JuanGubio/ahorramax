"use client"

import type React from "react"

import { useState } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { ArrowLeft, Camera, Mail, Phone, MapPin, User, LogOut, Share2, QrCode } from "lucide-react"

export default function ProfilePage() {
  const router = useRouter()
  const [userName, setUserName] = useState("María García")
  const [email, setEmail] = useState("maria.garcia@email.com")
  const [phone, setPhone] = useState("+52 55 1234 5678")
  const [location, setLocation] = useState("Ciudad de México, México")
  const [memberSince] = useState("Enero 2025")
  const [showShareModal, setShowShareModal] = useState(false)
  const [profileImage, setProfileImage] = useState<string>("/placeholder.svg?height=96&width=96")

  const handleLogout = () => {
    localStorage.removeItem("user")
    router.push("/")
  }

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      const reader = new FileReader()
      reader.onloadend = () => {
        setProfileImage(reader.result as string)
      }
      reader.readAsDataURL(file)
    }
  }

  const inviteCode = "AHORRA2025MG"
  const shareUrl = `https://ahorramax.app/invite/${inviteCode}`

  const handleCopyLink = () => {
    navigator.clipboard.writeText(shareUrl)
    alert("¡Enlace copiado al portapapeles!")
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b border-border bg-card sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex items-center gap-4">
          <Button asChild variant="ghost" size="icon" className="rounded-xl">
            <Link href="/dashboard">
              <ArrowLeft className="w-5 h-5" />
            </Link>
          </Button>
          <h1 className="text-xl font-bold">Mi Perfil</h1>
        </div>
      </header>

      <div className="container mx-auto px-4 py-6 md:py-8 max-w-2xl">
        {/* Profile Header */}
        <Card className="p-6 md:p-8 mb-6">
          <div className="flex flex-col items-center text-center space-y-4">
            <div className="relative">
              <Avatar className="w-24 h-24 border-4 border-primary">
                <AvatarImage src={profileImage || "/placeholder.svg"} />
                <AvatarFallback className="bg-primary text-white text-2xl">MG</AvatarFallback>
              </Avatar>
              <label
                htmlFor="profile-upload"
                className="absolute bottom-0 right-0 w-8 h-8 rounded-full bg-primary text-white flex items-center justify-center hover:bg-primary-dark transition-colors cursor-pointer"
              >
                <Camera className="w-4 h-4" />
                <input
                  id="profile-upload"
                  type="file"
                  accept="image/*"
                  onChange={handleImageUpload}
                  className="hidden"
                />
              </label>
            </div>

            <div>
              <h2 className="text-2xl font-bold">{userName}</h2>
              <p className="text-muted">Miembro desde {memberSince}</p>
            </div>

            <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 text-primary text-sm font-medium">
              <span className="w-2 h-2 rounded-full bg-primary animate-pulse"></span>
              <span>Cuenta Activa</span>
            </div>

            <Button
              onClick={() => setShowShareModal(true)}
              className="rounded-full bg-gradient-to-r from-primary to-secondary text-white px-6 py-2 font-bold hover:scale-105 transition-transform"
            >
              <Share2 className="w-4 h-4 mr-2" />
              Invitar amigos
            </Button>
          </div>
        </Card>

        {/* Stats Cards */}
        <div className="grid grid-cols-3 gap-4 mb-6">
          <Card className="p-4 text-center">
            <p className="text-2xl font-bold text-primary">24</p>
            <p className="text-xs text-muted">Días ahorrando</p>
          </Card>
          <Card className="p-4 text-center">
            <p className="text-2xl font-bold text-secondary">$3.2K</p>
            <p className="text-xs text-muted">Total ahorrado</p>
          </Card>
          <Card className="p-4 text-center">
            <p className="text-2xl font-bold text-accent">15%</p>
            <p className="text-xs text-muted">Meta alcanzada</p>
          </Card>
        </div>

        {/* Personal Information */}
        <Card className="p-6 md:p-8 space-y-6">
          <h3 className="text-xl font-bold">Información Personal</h3>

          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="name" className="flex items-center gap-2 text-muted">
                <User className="w-4 h-4" />
                Nombre completo
              </Label>
              <Input id="name" value={userName} onChange={(e) => setUserName(e.target.value)} className="rounded-xl" />
            </div>

            <div className="space-y-2">
              <Label htmlFor="email" className="flex items-center gap-2 text-muted">
                <Mail className="w-4 h-4" />
                Correo electrónico
              </Label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="rounded-xl"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="phone" className="flex items-center gap-2 text-muted">
                <Phone className="w-4 h-4" />
                Teléfono
              </Label>
              <Input
                id="phone"
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="rounded-xl"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="location" className="flex items-center gap-2 text-muted">
                <MapPin className="w-4 h-4" />
                Ubicación
              </Label>
              <Input
                id="location"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                className="rounded-xl"
              />
            </div>
          </div>

          <Button className="w-full rounded-full bg-primary hover:bg-primary-dark text-white h-12">
            Guardar cambios
          </Button>
        </Card>

        {/* Preferences */}
        <Card className="p-6 md:p-8 mt-6 space-y-4">
          <h3 className="text-xl font-bold">Preferencias</h3>

          <div className="space-y-3">
            <Button variant="outline" className="w-full justify-start rounded-xl h-12 bg-transparent">
              Notificaciones
            </Button>
            <Button variant="outline" className="w-full justify-start rounded-xl h-12 bg-transparent">
              Seguridad y privacidad
            </Button>
            <Button variant="outline" className="w-full justify-start rounded-xl h-12 bg-transparent">
              Conectar banco
            </Button>
            <Button
              onClick={handleLogout}
              variant="outline"
              className="w-full justify-start rounded-xl h-12 text-red-500 hover:text-red-600 hover:bg-red-50 bg-transparent"
            >
              <LogOut className="w-4 h-4 mr-2" />
              Cerrar sesión
            </Button>
          </div>
        </Card>
      </div>

      {showShareModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm animate-in fade-in duration-300 p-4">
          <div className="bg-card p-6 rounded-3xl shadow-2xl max-w-md w-full text-center animate-in zoom-in duration-300">
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center">
              <Share2 className="w-8 h-8 text-white" />
            </div>

            <h3 className="text-2xl font-bold mb-3">Invita a tus amigos</h3>
            <p className="text-muted mb-6">Ayuda a tus amigos a ahorrar mejor con AhorraMax</p>

            {/* Código QR */}
            <div className="bg-white p-6 rounded-2xl mb-6 border-2 border-border">
              <div className="w-48 h-48 mx-auto bg-gradient-to-br from-primary/20 to-secondary/20 rounded-xl flex items-center justify-center mb-4">
                <QrCode className="w-32 h-32 text-primary" />
              </div>
              <p className="text-sm font-bold text-foreground">Código: {inviteCode}</p>
            </div>

            {/* Enlace para compartir */}
            <div className="bg-muted/50 p-4 rounded-xl mb-4">
              <p className="text-sm text-muted mb-2">Tu enlace de invitación:</p>
              <p className="text-xs font-mono text-foreground break-all">{shareUrl}</p>
            </div>

            <div className="flex gap-3">
              <Button
                variant="outline"
                onClick={() => setShowShareModal(false)}
                className="flex-1 rounded-xl py-6 font-bold"
              >
                Cerrar
              </Button>
              <Button
                onClick={handleCopyLink}
                className="flex-1 rounded-xl py-6 font-bold bg-gradient-to-r from-primary to-secondary text-white hover:scale-[1.02] transition-transform"
              >
                Copiar enlace
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
