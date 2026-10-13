document.addEventListener('DOMContentLoaded', () => {
  // --- Theme Management ---
  const applyTheme = (theme) => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('demoTheme', theme);
    const toggles = document.querySelectorAll('#themeToggleBtn, [data-theme-toggle]');
    toggles.forEach((btn) => {
      btn.setAttribute('aria-checked', theme === 'dark' ? 'true' : 'false');
    });
  };
  
  const currentTheme = localStorage.getItem('demoTheme') || 'dark';
  applyTheme(currentTheme);

  const themeToggleBtns = document.querySelectorAll('#themeToggleBtn, [data-theme-toggle]');
  themeToggleBtns.forEach((btn) => {
    btn.addEventListener('click', () => {
      const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
      applyTheme(isDark ? 'light' : 'dark');
    });
  });

  // --- Login Page Logic ---
  const step1 = document.getElementById('step-1');
  const step2 = document.getElementById('step-2');
  
  if (step1 && step2) {
    const emailInput = document.getElementById('work-email');
    const emailFormGrp = document.getElementById('email-form-group');
    const emailErrorMsg = document.getElementById('email-error-msg');
    
    const pwdInput = document.getElementById('work-password');
    const pwdFormGrp = document.getElementById('password-form-group');
    const pwdErrorMsg = document.getElementById('password-error-msg');
    
    const displayEmail = document.getElementById('display-email');
    const changeEmailBtn = document.getElementById('change-email-btn');
    const nextBtn = document.getElementById('next-btn');
    const signinBtn = document.getElementById('signin-btn');
    const togglePwdBtn = document.getElementById('toggle-pwd');

    const validRoles = {
      'owner@app-demo.com': 'owner/index.html',
      'admin@app-demo.com': 'admin/index.html',
      'approver@app-demo.com': 'approver/index.html',
      'user1@app-demo.com': 'user1/index.html',
      'user2@app-demo.com': 'user2/index.html'
    };

    nextBtn.addEventListener('click', (e) => {
      e.preventDefault();
      const email = emailInput.value.trim().toLowerCase();
      emailFormGrp.classList.remove('has-error');
      
      if (!email) {
        emailErrorMsg.textContent = 'Please enter an email address';
        emailFormGrp.classList.add('has-error');
        return;
      }
      
      if (!email.match(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)) {
        emailErrorMsg.textContent = 'Invalid email address.';
        emailFormGrp.classList.add('has-error');
        return;
      }

      let redirectPage = validRoles[email];
      
      if (!redirectPage) {
        if (email.startsWith('owner')) redirectPage = 'owner/index.html';
        else if (email.startsWith('admin')) redirectPage = 'admin/index.html';
        else if (email.startsWith('approver')) redirectPage = 'approver/index.html';
        else if (email.startsWith('user1')) redirectPage = 'user1/index.html';
        else if (email.startsWith('user2')) redirectPage = 'user2/index.html';
        else {
          emailErrorMsg.textContent = 'Invalid email address.';
          emailFormGrp.classList.add('has-error');
          return;
        }
      }

      sessionStorage.setItem('demoRedirectUrl', redirectPage);
      sessionStorage.setItem('demoEmail', email);

      displayEmail.textContent = email;
      step1.style.display = 'none';
      step2.style.display = 'block';
    });

    changeEmailBtn.addEventListener('click', (e) => {
      e.preventDefault();
      step2.style.display = 'none';
      step1.style.display = 'block';
    });

    togglePwdBtn.addEventListener('click', (e) => {
      e.preventDefault();
      const isPwd = pwdInput.getAttribute('type') === 'password';
      pwdInput.setAttribute('type', isPwd ? 'text' : 'password');
      
      if (isPwd) {
        // Open eye
        togglePwdBtn.innerHTML = '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="20" height="20"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>';
      } else {
        // Crossed eye
        togglePwdBtn.innerHTML = '<svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="20" height="20"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21"></path></svg>';
      }
    });

    signinBtn.addEventListener('click', (e) => {
      e.preventDefault();
      const pwd = pwdInput.value.trim();
      pwdFormGrp.classList.remove('has-error');
      
      if (!pwd) {
        pwdErrorMsg.textContent = 'Password is required';
        pwdFormGrp.classList.add('has-error');
        return;
      }

      const redirectUrl = sessionStorage.getItem('demoRedirectUrl') || 'owner/index.html';
      window.location.href = redirectUrl;
    });
  }

  // --- Dashboard Logic ---
  const profileTrigger = document.getElementById('profileTrigger');
  const profileDropdown = document.getElementById('profileDropdown');

  const orgDisplays = document.querySelectorAll('.profile-org');
  if (orgDisplays.length > 0) {
    const email = sessionStorage.getItem('demoEmail') || 'owner@app-demo.com';
    const domain = email.split('@')[1] || 'app-demo.com';
    const rawOrg = domain.split('.')[0];
    const orgName = rawOrg.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
    orgDisplays.forEach(el => {
      el.textContent = orgName;
    });
  }
  
  if (profileTrigger && profileDropdown) {
    profileTrigger.addEventListener('click', (e) => {
      e.stopPropagation();
      profileDropdown.classList.toggle('show');
    });

    document.addEventListener('click', (e) => {
      if (!profileDropdown.contains(e.target)) {
        profileDropdown.classList.remove('show');
      }
    });

    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', (e) => {
        e.preventDefault();
        sessionStorage.removeItem('demoEmail');
        sessionStorage.removeItem('demoRedirectUrl');
        window.location.href = '../index.html';
      });
    }
  }

  const desktopToggle = document.getElementById('menuToggleDesktop');
  const mobileToggle = document.getElementById('menuToggleMobile');
  const sidebar = document.getElementById('sidebar');
  
  if (sidebar) {
    if (window.innerWidth <= 768) {
      sidebar.classList.add('collapsed');
    }

    let lastWidth = window.innerWidth;
    window.addEventListener('resize', () => {
      const currentWidth = window.innerWidth;
      if (lastWidth > 768 && currentWidth <= 768) {
        sidebar.classList.add('collapsed');
      } else if (lastWidth <= 768 && currentWidth > 768) {
        sidebar.classList.remove('collapsed');
      }
      lastWidth = currentWidth;
    });
  }

  const toggleSidebar = () => {
    sidebar.classList.toggle('collapsed');
  };

  if (desktopToggle && sidebar) {
    desktopToggle.addEventListener('click', toggleSidebar);
  }
  if (mobileToggle && sidebar) {
    mobileToggle.addEventListener('click', toggleSidebar);
  }
});
