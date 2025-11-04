import { BASE_PRICE, PRODUCT_PRICES } from '@/config/products'
import { db } from '@/db'
import { stripe } from '@/lib/stripe'
import { getKindeServerSession } from '@kinde-oss/kinde-auth-nextjs/server'
import { NextResponse } from 'next/server'

export async function POST(req: Request) {
  try {
    const { configId } = await req.json()
    if (!configId || typeof configId !== 'string') {
      return NextResponse.json({ error: 'Missing or invalid configId' }, { status: 400 })
    }

    const configuration = await db.configuration.findUnique({
      where: { id: configId },
    })
    if (!configuration) {
      return NextResponse.json({ error: 'No such configuration found' }, { status: 404 })
    }

    const { getUser } = getKindeServerSession()
    const user = await getUser()
    if (!user) {
      return NextResponse.json({ error: 'You need to be logged in' }, { status: 401 })
    }

    // Ensure user exists in the database before creating an order
    await db.user.upsert({
      where: { id: user.id },
      update: {},
      create: {
        id: user.id,
        email: user.email ?? '',
      },
    });

    const { finish, material } = configuration

    let price = BASE_PRICE
    if (finish === 'textured') price += PRODUCT_PRICES.finish.textured
    if (material === 'polycarbonate') price += PRODUCT_PRICES.material.polycarbonate

    let order = await db.order.findFirst({
      where: { userId: user.id, configurationId: configuration.id },
    })
    if (!order) {
      order = await db.order.create({
        data: {
          amount: price / 100, // Check if amount should be price directly
          userId: user.id,
          configurationId: configuration.id,
        },
      })
    }

    const product = await stripe.products.create({
      name: 'Custom iPhone Case',
      images: [configuration.imageUrl],
      default_price_data: {
        currency: 'USD',
        unit_amount: price,
      },
    })

    const stripeSession = await stripe.checkout.sessions.create({
      success_url: `${process.env.NEXT_PUBLIC_SERVER_URL}/thank-you?orderId=${order.id}`,
      cancel_url: `${process.env.NEXT_PUBLIC_SERVER_URL}/configure/preview?id=${configuration.id}`,
      payment_method_types: ['card'],
      mode: 'payment',
      shipping_address_collection: { allowed_countries: ['DE', 'US'] },
      metadata: {
        userId: user.id,
        orderId: order.id,
      },
      line_items: [{ price: product.default_price as string, quantity: 1 }],
    })

    return NextResponse.json({ url: stripeSession.url })
  } catch (error) {
    console.error('API Checkout Error:', error)
    return NextResponse.json({ error: (error instanceof Error ? error.message : String(error)) || 'Internal server error' }, { status: 500 })
  }
}
