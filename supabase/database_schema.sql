-- Database schema for AssetCraft AI

-- User assets table
CREATE TABLE user_assets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  prompt TEXT NOT NULL,
  aspect_ratio TEXT DEFAULT '1:1',
  asset_type TEXT,
  metadata JSONB DEFAULT '{}',
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Generation history table
CREATE TABLE generation_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  prompt TEXT NOT NULL,
  image_url TEXT NOT NULL,
  aspect_ratio TEXT DEFAULT '1:1',
  asset_type TEXT,
  generation_time_seconds INTEGER,
  cost_in_gemstones INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User profiles table (for gemstones, etc.)
CREATE TABLE user_profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  display_name TEXT,
  avatar_url TEXT,
  gemstone_count INTEGER DEFAULT 10,
  subscription_status TEXT DEFAULT 'free',
  subscription_end_date TIMESTAMP WITH TIME ZONE,
  total_generations INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX idx_user_assets_user_id ON user_assets(user_id);
CREATE INDEX idx_user_assets_created_at ON user_assets(created_at DESC);
CREATE INDEX idx_generation_history_user_id ON generation_history(user_id);
CREATE INDEX idx_generation_history_created_at ON generation_history(created_at DESC);

-- Row Level Security (RLS)
ALTER TABLE user_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE generation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own assets" ON user_assets
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own assets" ON user_assets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own assets" ON user_assets
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own assets" ON user_assets
  FOR DELETE USING (auth.uid() = user_id);

-- Similar policies for other tables
CREATE POLICY "Users can view their own history" ON generation_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own history" ON generation_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Function to create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, display_name, gemstone_count)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'display_name', 10);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
