# 🗄️ Supabase Database Setup

To get the **PawStay** backend running, you can copy and paste the following SQL commands into your Supabase SQL Editor.

## 1. Tables Setup

### Hosts Table
```sql
-- Create the hosts table
create table hosts (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null,
  name text not null,
  title text not null,
  location text not null,
  price numeric not null,
  bio text,
  category text,
  rating numeric default 5.0,
  is_verified boolean default false,
  image_url text,
  created_at timestamptz default now()
);

-- Row Level Security (RLS)
alter table hosts enable row level security;

create policy "Hosts are viewable by everyone" 
on hosts for select using (true);

create policy "Users can update their own host profile" 
on hosts for update using (auth.uid() = user_id);

create policy "Users can insert their own host profile" 
on hosts for insert with check (auth.uid() = user_id);
```

### Pets Table
```sql
-- Create the pets table
create table pets (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid references auth.users not null,
  name text not null,
  breed text,
  weight text,
  age text,
  image_url text,
  notes text,
  created_at timestamptz default now()
);

-- Row Level Security (RLS)
alter table pets enable row level security;

create policy "Pets are viewable by their owners" 
on pets for select using (auth.uid() = owner_id);

create policy "Owners can manage their pets" 
on pets for all using (auth.uid() = owner_id);
```

### Bookings Table
```sql
-- Create the bookings table
create table bookings (
  id uuid primary key default uuid_generate_v4(),
  host_id uuid references hosts(id) not null,
  pet_id uuid references pets(id) not null,
  user_id uuid references auth.users not null, -- The guest/owner
  status text default 'pending', -- pending, confirmed, cancelled
  total_price numeric,
  nights integer,
  start_date date,
  end_date date,
  created_at timestamptz default now()
);

-- Row Level Security (RLS)
alter table bookings enable row level security;

create policy "Users can view their own bookings" 
on bookings for select using (auth.uid() = user_id);

create policy "Hosts can view bookings sent to them" 
on bookings for select using (
  exists (
    select 1 from hosts 
    where hosts.id = bookings.host_id 
    and hosts.user_id = auth.uid()
  )
);

create policy "Users can insert their own bookings" 
on bookings for insert with check (auth.uid() = user_id);
```

### Wishlists Table
```sql
-- Create the wishlists table
create table wishlists (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users not null,
  host_id uuid references hosts(id) not null,
  created_at timestamptz default now(),
  unique(user_id, host_id)
);

-- Row Level Security (RLS)
alter table wishlists enable row level security;

create policy "Users can manage their own wishlist" 
on wishlists for all using (auth.uid() = user_id);
```

### Messages (Chat) Table
```sql
-- Create the messages table for chat
create table messages (
  id uuid primary key default uuid_generate_v4(),
  sender_id uuid references auth.users not null,
  receiver_id uuid references auth.users not null,
  content text not null,
  sender_name text,
  receiver_name text,
  created_at timestamptz default now()
);

-- Row Level Security (RLS)
alter table messages enable row level security;

create policy "Users can view their own conversations" 
on messages for select using (
  auth.uid() = sender_id or auth.uid() = receiver_id
);

create policy "Users can send messages" 
on messages for insert with check (auth.uid() = sender_id);
```

---

## 2. Storage Setup

You will need to create a **public** bucket in Supabase Storage:

1.  **Name**: `hosts`
2.  **Public**: Yes
3.  **Policy**: Allow **Authenticated** users to upload/update their own files in the `hosts/` folder.

```sql
-- Storage Policies (Run in SQL Editor or set in Dashboard)
create policy "Authenticated users can upload host images"
on storage.objects for insert
with check ( bucket_id = 'hosts' AND auth.role() = 'authenticated' );

create policy "Host images are public"
on storage.objects for select
using ( bucket_id = 'hosts' );
```

---

🐾 *Happy coding with PawStay!*
