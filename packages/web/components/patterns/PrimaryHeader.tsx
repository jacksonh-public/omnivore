import { Box, HStack } from '../elements/LayoutPrimitives'
import { OmnivoreNameLogo } from './../elements/images/OmnivoreNameLogo'
import { DropdownMenu, HeaderDropdownAction } from './../patterns/DropdownMenu'
import { updateTheme } from '../../lib/themeUpdater'
import { AvatarDropdown } from './../elements/AvatarDropdown'
import { ThemeId } from './../tokens/stitches.config'
import { useCallback, useEffect, useState } from 'react'
import {
  ScrollOffsetChangeset,
  useScrollWatcher,
} from '../../lib/hooks/useScrollWatcher'
import { useRouter } from 'next/router'
import { useKeyboardShortcuts } from '../../lib/keyboardShortcuts/useKeyboardShortcuts'
import { primaryCommands } from '../../lib/keyboardShortcuts/navigationShortcuts'
import { darkenTheme, lightenTheme } from '../../lib/themeUpdater'
import { UserBasicData } from '../../lib/networking/queries/useGetViewerQuery'
import { setupAnalytics } from '../../lib/analytics'
import { Button } from '../elements/Button'
import Link from 'next/link'

type HeaderProps = {
  user?: UserBasicData
  userInitials: string
  hideHeader?: boolean
  profileImageURL?: string
  isFixedPosition: boolean
  scrollElementRef?: React.RefObject<HTMLDivElement>
  displayFontStepper?: boolean
  setShowLogoutConfirmation: (showShareModal: boolean) => void
  setShowKeyboardCommandsModal: (showShareModal: boolean) => void
}

export function PrimaryHeader(props: HeaderProps): JSX.Element {
  const router = useRouter()
  const [isScrolled, setIsScrolled] = useState(false)

  useKeyboardShortcuts(
    primaryCommands((action) => {
      switch (action) {
        case 'themeDarker':
          darkenTheme()
          break
        case 'themeLighter':
          lightenTheme()
          break
        case 'toggleShortcutHelpModalDisplay':
          props.setShowKeyboardCommandsModal(true)
          break
      }
    })
  )

  const setScrollWatchedElement = useScrollWatcher(
    (changeset: ScrollOffsetChangeset) => {
      const isScrolledBeyondMinThreshold = changeset.current.y >= 50
      const isScrollingDown = changeset.current.y > changeset.previous.y

      // setIsScrolled(isScrolledBeyondMinThreshold)
      // setShowHeader(!(isScrollingDown && isScrolledBeyondMinThreshold))
    },
    0
  )

  useEffect(() => {
    if (props.scrollElementRef) {
      setScrollWatchedElement(props.scrollElementRef.current)
    }
  }, [props.scrollElementRef, setScrollWatchedElement])

  const initAnalytics = useCallback(() => {
    setupAnalytics(props.user)
  }, [props.user])

  useEffect(() => {
    initAnalytics()
    window.addEventListener('load', initAnalytics)
    return () => {
      window.removeEventListener('load', initAnalytics)
    }
  }, [initAnalytics])

  function headerDropdownActionHandler(action: HeaderDropdownAction): void {
    switch (action) {
      case 'apply-darker-theme':
        updateTheme(ThemeId.Darker)
        break
      case 'apply-dark-theme':
        updateTheme(ThemeId.Dark)
        break
      case 'apply-lighter-theme':
        updateTheme(ThemeId.Lighter)
        break
      case 'apply-light-theme':
        updateTheme(ThemeId.Light)
        break
      case 'increaseFontSize':
        document.dispatchEvent(new Event('increaseFontSize'))
        break
      case 'decreaseFontSize':
        document.dispatchEvent(new Event('decreaseFontSize'))
        break
      case 'navigate-to-install':
        router.push('/settings/installation')
        break
      case 'navigate-to-feedback':
        console.log('navigate to feedback - unimplemented') // TODO: implement intercom
        break
      case 'navigate-to-profile':
        if (props.user) {
          router.push(`/${props.user.profile.username}`)
        }
        break
      case 'logout':
        props.setShowLogoutConfirmation(true)
        break
      default:
        break
    }
  }

  return (
    <>
      <NavHeader
        {...props}
        username={props.user?.profile.username}
        actionHandler={headerDropdownActionHandler}
        isDisplayingShadow={isScrolled}
        isVisible={true}
        isFixedPosition={true}
        displayFontStepper={props.displayFontStepper}
      />
    </>
  )
}

// Separating out component so we can extract to design system
type NavHeaderProps = {
  username?: string
  userInitials: string
  actionHandler: (action: HeaderDropdownAction) => void
  profileImageURL?: string
  isDisplayingShadow?: boolean
  isVisible?: boolean
  isFixedPosition: boolean
  displayFontStepper?: boolean
}

function NavHeader(props: NavHeaderProps): JSX.Element {
  const router = useRouter()
  const currentPath = decodeURI(router.asPath)

  return (
    <nav>
      <HStack
        alignment="center"
        distribution="between"
        css={{
          zIndex: 5,
          width: '100%',
          boxShadow: props.isDisplayingShadow ? '$panelShadow' : 'unset',
          bg: '$grayBase',
          p: '0px $3 0px $3',
          height: '68px',
          position: 'fixed',
          minHeight: '68px',
          '@smDown': {
            height: '48px',
            minHeight: '48px',
            p: '0px 18px 0px 16px',
          },
        }}
      >
        <HStack alignment="center" distribution="start">
          <Box
            css={{
              display: 'flex',
              alignItems: 'center',
              paddingRight: '10px',
            }}
          >
            <OmnivoreNameLogo href={props.username ? '/home' : '/login'} />
          </Box>
          <NavLinks currentPath={currentPath} isLoggedIn={!!props.username} />
        </HStack>
        {props.username ? (
          <HStack
            alignment="center"
            css={{ display: 'flex', alignItems: 'center' }}
          >
            <DropdownMenu
              username={props.username}
              triggerElement={
                <AvatarDropdown
                  userInitials={props.userInitials}
                  profileImageURL={props.profileImageURL}
                />
              }
              actionHandler={props.actionHandler}
              displayFontStepper={props.displayFontStepper}
            />
          </HStack>
        ) : (
          <Link passHref href="/login">
            <Button style="ctaDarkYellow">Sign Up</Button>
          </Link>
        )}
      </HStack>
    </nav>
  )
}

type UserNavLinksProps = {
  isLoggedIn: boolean
  currentPath: string
}

function NavLinks(props: UserNavLinksProps): JSX.Element {
  return (
    <>
      {/* <HeaderNavLink
        isActive={props.currentPath.startsWith('/home')}
        href={props.isLoggedIn ? '/home' : '/login'}
        text="Home"
      /> */}
      {/* <HeaderNavLink
        isActive={props.currentPath == '/discover'}
        href="/discover"
        text="Discover"
      /> */}
    </>
  )
}
