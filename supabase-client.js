
(function(){
  if(!window.JPFIT_CONFIG) throw new Error("Missing JP Fit Supabase configuration.");
  window.jpSupabase = supabase.createClient(
    window.JPFIT_CONFIG.SUPABASE_URL,
    window.JPFIT_CONFIG.SUPABASE_PUBLISHABLE_KEY
  );

  window.jpGetUser = async function(){
    const { data, error } = await window.jpSupabase.auth.getUser();
    if(error) return null;
    return data.user || null;
  };

  window.jpRequireUser = async function(redirect="auth.html"){
    const user = await window.jpGetUser();
    if(!user){
      const next = encodeURIComponent(location.pathname + location.search);
      location.href = `${redirect}?next=${next}`;
      return null;
    }
    return user;
  };

  window.jpSignOut = async function(){
    await window.jpSupabase.auth.signOut();
    location.href = "auth.html";
  };
})();
