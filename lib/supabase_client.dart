import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://ewuxtrsbzdoofkqplzbf.supabase.co';
const supabaseAnonKey = 'sb_publishable_dGlI07F-irHrt2zrgnszIA_Gbr9skVL';

final supabase = Supabase.instance.client;

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
}