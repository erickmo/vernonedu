import { LINKS } from './tokens'

it('LINKS.register points to frontend app', () => {
  expect(LINKS.register).toContain('/register')
})
