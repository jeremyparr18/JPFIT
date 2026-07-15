// JP Fit analytics configuration
// Replace G-XXXXXXXXXX with your Google Analytics 4 Measurement ID.
// Example: const JP_FIT_GA_ID = "G-ABC123DEF4";
const JP_FIT_GA_ID = "G-F6Z5QZ69VG";

(function initializeJPFitAnalytics() {
  if (!JP_FIT_GA_ID || JP_FIT_GA_ID === "G-XXXXXXXXXX") {
    console.info("JP Fit Analytics: add your GA4 Measurement ID in analytics-config.js");
    return;
  }

  const script = document.createElement("script");
  script.async = true;
  script.src = `https://www.googletagmanager.com/gtag/js?id=${encodeURIComponent(JP_FIT_GA_ID)}`;
  document.head.appendChild(script);

  window.dataLayer = window.dataLayer || [];
  window.gtag = function gtag(){ window.dataLayer.push(arguments); };
  window.gtag("js", new Date());
  window.gtag("config", JP_FIT_GA_ID, {
    anonymize_ip: true,
    send_page_view: true
  });
})();

window.jpTrackEvent = function jpTrackEvent(name, parameters = {}) {
  if (typeof window.gtag !== "function") return;
  window.gtag("event", name, parameters);
};
