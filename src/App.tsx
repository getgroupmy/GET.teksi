import { useEffect } from 'react'
import { Navigate, Route, Routes, useLocation, useNavigate } from 'react-router-dom'
import { requestGeolocation, useSession } from '@/store/session'
import { startSimulation, stopSimulation } from '@/services/simulation'
import { useRides } from '@/store/rides'

import Intro from '@/screens/auth/Intro'
import PhoneScreen from '@/screens/auth/Phone'
import OtpScreen from '@/screens/auth/Otp'
import ProfileSetup from '@/screens/auth/ProfileSetup'

import PassengerHome from '@/screens/passenger/Home'
import DestinationSearch from '@/screens/passenger/DestinationSearch'
import ChatScreen from '@/screens/shared/Chat'
import RateScreen from '@/screens/shared/Rate'

import DriverHome from '@/screens/driver/Home'
import DriverOrder from '@/screens/driver/OrderDetail'
import DriverEarnings from '@/screens/driver/Earnings'
import DriverVehicle from '@/screens/driver/Vehicle'
import DriverOnboarding from '@/screens/driver/Onboarding'

import Menu from '@/screens/shared/Menu'
import History from '@/screens/shared/History'
import RideDetail from '@/screens/shared/RideDetail'
import Wallet from '@/screens/shared/Wallet'
import Settings from '@/screens/shared/Settings'
import Notifications from '@/screens/shared/Notifications'
import Safety from '@/screens/shared/Safety'
import Promos from '@/screens/shared/Promos'
import Profile from '@/screens/shared/Profile'
import Places from '@/screens/shared/Places'

export default function App() {
  const user = useSession((s) => s.user)
  const prefs = useSession((s) => s.prefs)
  const location = useLocation()
  const navigate = useNavigate()

  useEffect(() => {
    document.documentElement.dataset.theme = prefs.theme
  }, [prefs.theme])

  useEffect(() => {
    requestGeolocation()
  }, [])

  // The bot marketplace runs only while signed in and enabled in settings.
  useEffect(() => {
    if (user && prefs.simulationEnabled) startSimulation()
    else stopSimulation()
    return () => stopSimulation()
  }, [user, prefs.simulationEnabled])

  // Expire stale offers even when the simulation is off.
  useEffect(() => {
    const id = window.setInterval(() => useRides.getState().sweep(), 3000)
    return () => window.clearInterval(id)
  }, [])

  // Switching roles lands you on that role's home screen. Driver onboarding is
  // exempt — a passenger has to be able to open it to become a driver at all.
  useEffect(() => {
    const onPassengerRoute = location.pathname.startsWith('/p')
    const onDriverRoute =
      location.pathname.startsWith('/d') && location.pathname !== '/d/onboarding'
    if (prefs.role === 'driver' && onPassengerRoute) navigate('/d', { replace: true })
    if (prefs.role === 'passenger' && onDriverRoute) navigate('/p', { replace: true })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [prefs.role])

  const home = prefs.role === 'driver' ? '/d' : '/p'

  return (
    <div className="app-frame">
      <Routes>
        {!user ? (
          <>
            <Route path="/intro" element={<Intro />} />
            <Route path="/auth/phone" element={<PhoneScreen />} />
            <Route path="/auth/otp" element={<OtpScreen />} />
            <Route path="/auth/profile" element={<ProfileSetup />} />
            <Route
              path="*"
              element={<Navigate to={prefs.hasSeenIntro ? '/auth/phone' : '/intro'} replace />}
            />
          </>
        ) : (
          <>
            <Route path="/p" element={<PassengerHome />} />
            <Route path="/p/search" element={<DestinationSearch />} />

            <Route path="/d" element={<DriverHome />} />
            <Route path="/d/order/:rideId" element={<DriverOrder />} />
            <Route path="/d/earnings" element={<DriverEarnings />} />
            <Route path="/d/vehicle" element={<DriverVehicle />} />
            <Route path="/d/onboarding" element={<DriverOnboarding />} />

            <Route path="/chat/:rideId" element={<ChatScreen />} />
            <Route path="/rate/:rideId" element={<RateScreen />} />
            <Route path="/ride/:rideId" element={<RideDetail />} />

            <Route path="/menu" element={<Menu />} />
            <Route path="/history" element={<History />} />
            <Route path="/wallet" element={<Wallet />} />
            <Route path="/settings" element={<Settings />} />
            <Route path="/notifications" element={<Notifications />} />
            <Route path="/safety" element={<Safety />} />
            <Route path="/promos" element={<Promos />} />
            <Route path="/profile" element={<Profile />} />
            <Route path="/places" element={<Places />} />

            <Route path="*" element={<Navigate to={home} replace />} />
          </>
        )}
      </Routes>
    </div>
  )
}
