import { useState } from 'react'
import { Mail, Phone, MapPin, Clock, CheckCircle } from 'lucide-react'
import { Container } from '../components/ui/Container'
import { PageHeader } from '../components/ui/PageHeader'
import { Card, CardHeader, CardBody } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { Field, inputClass, textareaClass, selectClass } from '../components/ui/Field'

export function Contact() {
  const [submitted, setSubmitted] = useState(false)

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setSubmitted(true)
  }

  return (
    <div className="bg-slate-50 min-h-screen">
      <Container className="py-8">
        <PageHeader
          title="Contact"
          description="We're here to help with any questions about your energy plan."
        />

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* ── Contact info ────────────────────────────────── */}
          <div className="space-y-4">
            <Card>
              <CardBody>
                <h2 className="font-semibold text-slate-900">Contact details</h2>
                <ul className="mt-4 space-y-3">
                  {[
                    { icon: Phone,  text: '0800 – 1234 567' },
                    { icon: Mail,   text: 'service@northwindenergy.nl' },
                    { icon: MapPin, text: 'Energieplein 1, 1234 AB Amsterdam' },
                    { icon: Clock,  text: 'Mon – Fri, 08:00 – 18:00' },
                  ].map(({ icon: Icon, text }) => (
                    <li key={text} className="flex items-start gap-3 text-sm text-slate-700">
                      <Icon className="h-4 w-4 text-brand-600 mt-0.5 shrink-0" />
                      {text}
                    </li>
                  ))}
                </ul>
              </CardBody>
            </Card>

            <Card>
              <CardBody>
                <h2 className="font-semibold text-slate-900">Emergency line</h2>
                <p className="mt-2 text-sm text-slate-600">
                  For power outages or gas smell, call your grid operator immediately.
                </p>
                <p className="mt-2 text-sm font-semibold text-slate-900">0800 – 9009</p>
                <p className="text-xs text-slate-500">Available 24/7</p>
              </CardBody>
            </Card>
          </div>

          {/* ── Contact form ──────────────────────────────────── */}
          <Card className="lg:col-span-2">
            <CardHeader>
              <h2 className="text-lg font-semibold text-slate-900">Send us a message</h2>
            </CardHeader>
            <CardBody>
              {submitted ? (
                <div className="py-10 text-center">
                  <CheckCircle className="h-12 w-12 text-emerald-500 mx-auto mb-3" />
                  <p className="font-semibold text-slate-900 text-lg">Message sent</p>
                  <p className="text-slate-500 mt-1 text-sm">
                    We'll get back to you within one business day.
                  </p>
                  <button
                    className="mt-5 text-sm text-brand-600 hover:underline"
                    onClick={() => setSubmitted(false)}
                  >
                    Send another message
                  </button>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <Field label="First name" htmlFor="first-name">
                      <input id="first-name" type="text" placeholder="Emma" className={inputClass} />
                    </Field>
                    <Field label="Last name" htmlFor="last-name">
                      <input
                        id="last-name"
                        type="text"
                        placeholder="van der Berg"
                        className={inputClass}
                      />
                    </Field>
                  </div>

                  <Field label="Email address" htmlFor="email">
                    <input
                      id="email"
                      type="email"
                      placeholder="emma@example.com"
                      className={inputClass}
                    />
                  </Field>

                  <Field label="Subject" htmlFor="subject">
                    <select id="subject" className={selectClass} defaultValue="">
                      <option value="" disabled>
                        Choose a subject…
                      </option>
                      <option>Question about my bill</option>
                      <option>Switching plans</option>
                      <option>Moving home</option>
                      <option>Meter reading</option>
                      <option>Other</option>
                    </select>
                  </Field>

                  <Field label="Message" htmlFor="message">
                    <textarea
                      id="message"
                      rows={4}
                      placeholder="How can we help you?"
                      className={textareaClass}
                    />
                  </Field>

                  <Button type="submit">Send message</Button>
                </form>
              )}
            </CardBody>
          </Card>
        </div>
      </Container>
    </div>
  )
}
