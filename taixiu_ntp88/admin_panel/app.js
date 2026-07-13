// ==========================================
// Macau Prestige - Admin Dashboard JS Logic
// ==========================================

// Firebase Configuration matching Flutter Client
const firebaseConfig = {
  apiKey: "AIzaSyDkybz8HmV-kJF7nIWGlD37x8ZUpL8CO4M",
  authDomain: "tai-xiu-ntp88.firebaseapp.com",
  projectId: "tai-xiu-ntp88",
  storageBucket: "tai-xiu-ntp88.firebasestorage.app",
  messagingSenderId: "159588266332",
  appId: "1:159588266332:web:fc2d2cc27ecaab8eda1199",
};

// Initialize Firebase
let db;
try {
  firebase.initializeApp(firebaseConfig);
  db = firebase.firestore();
  document.getElementById("db-status").innerText = "Đã kết nối";
  document.getElementById("db-status").className = "badge-offline badge-online";
} catch (error) {
  console.error("Firebase init failed:", error);
  document.getElementById("db-status").innerText = "Chưa kết nối";
  document.getElementById("db-status").className = "badge-offline";
}

// Global Variables
let currentSessionId = 0;
let currentGameState = "BETTING";
let activeTab = "dashboard";
let registeredUsers = [];
let activeBets = [];
let selectedUserIdForBalance = null;
let isDashboardInitialized = false;

// Firebase Unsubscribe functions
let activeBetsUnsubscribe = null;
let adminSettingsUnsubscribe = null;
let usersUnsubscribe = null;

// ==========================================
// AUTHENTICATION & SECURITY MANAGEMENT
// ==========================================

function showLoginError(message) {
  const errorDiv = document.getElementById("login-error-msg");
  const errorText = document.getElementById("login-error-text");
  errorText.innerText = message;
  errorDiv.style.display = "flex";
}

function initializeAdminDashboard() {
  if (isDashboardInitialized) return;
  isDashboardInitialized = true;

  // Start active listeners
  syncActiveBets();
  syncAdminSettings();
  syncUsersList();
}

function shutdownAdminDashboard() {
  isDashboardInitialized = false;

  // Unsubscribe from Firestore to prevent authorization errors
  if (activeBetsUnsubscribe) {
    activeBetsUnsubscribe();
    activeBetsUnsubscribe = null;
  }
  if (adminSettingsUnsubscribe) {
    adminSettingsUnsubscribe();
    adminSettingsUnsubscribe = null;
  }
  if (usersUnsubscribe) {
    usersUnsubscribe();
    usersUnsubscribe = null;
  }
}

// Firebase Auth State Observer
firebase.auth().onAuthStateChanged(async (user) => {
  if (user) {
    console.log("=== DEBUG ADMIN LOGIN ===");
    console.log("Logged in Email:", user.email);
    console.log("Logged in UID:", user.uid);
    try {
      // Fetch user profile from Firestore to verify role
      const userDoc = await db.collection("users").doc(user.uid).get();
      console.log("User Document exists in Firestore:", userDoc.exists);

      let hasAdminPermission = false;
      let fullName = "Admin";

      if (userDoc.exists) {
        const userData = userDoc.data();
        console.log("User data from Firestore:", userData);
        fullName = userData.fullName || user.email;
        if (userData.role === "admin" || userData.isAdmin === true) {
          hasAdminPermission = true;
        }
      } else {
        console.log("Warning: No user document found for UID:", user.uid);
      }

      // Predefined fallback for admin email
      if (
        user.email === "toanlk04@gmail.com" ||
        user.email === "admin@gmail.com" ||
        user.email === "toanlk290804@gmail.com"
      ) {
        console.log("Email matches fallback list, granting admin permission.");
        hasAdminPermission = true;
      }

      console.log("Final hasAdminPermission:", hasAdminPermission);

      if (hasAdminPermission) {
        // Show Admin Panel UI
        document.getElementById("login-wrapper").style.display = "none";
        document.getElementById("app-container").style.display = "grid";
        document.getElementById("admin-display-name").innerText = fullName;

        // Display initials in avatar
        const initials = fullName
          .split(" ")
          .map((n) => n[0])
          .join("")
          .substring(0, 2)
          .toUpperCase();
        document.getElementById("admin-avatar").innerText = initials || "AD";

        initializeAdminDashboard();
      } else {
        showLoginError(
          "Tài khoản của bạn không có quyền truy cập trang quản trị.",
        );
        await firebase.auth().signOut();
      }
    } catch (error) {
      console.error("Admin role verification error:", error);
      showLoginError("Lỗi xác thực quyền truy cập: " + error.message);
      await firebase.auth().signOut();
    }
  } else {
    // Show Login Form, Hide Admin Panel UI
    document.getElementById("login-wrapper").style.display = "flex";
    document.getElementById("app-container").style.display = "none";
    shutdownAdminDashboard();
  }
});

// Login Form Submit Event
document.getElementById("login-form").addEventListener("submit", (e) => {
  e.preventDefault();
  const email = document.getElementById("login-email").value.trim();
  const password = document.getElementById("login-password").value;
  const loginBtn = document.getElementById("btn-login-submit");

  loginBtn.disabled = true;
  loginBtn.innerHTML =
    '<i class="fa-solid fa-spinner fa-spin"></i> Đang Đăng Nhập...';
  document.getElementById("login-error-msg").style.display = "none";

  firebase
    .auth()
    .signInWithEmailAndPassword(email, password)
    .then(() => {
      loginBtn.disabled = false;
      loginBtn.innerHTML =
        '<i class="fa-solid fa-right-to-bracket"></i> Đăng Nhập';
    })
    .catch((error) => {
      console.error("Login failed:", error);
      let userFriendlyMsg = "Tài khoản hoặc mật khẩu không chính xác.";
      if (
        error.code === "auth/user-not-found" ||
        error.code === "auth/wrong-password" ||
        error.code === "auth/invalid-login-credentials"
      ) {
        userFriendlyMsg = "Email hoặc mật khẩu không chính xác.";
      } else if (error.code === "auth/invalid-email") {
        userFriendlyMsg = "Định dạng email không hợp lệ.";
      } else if (error.code === "auth/network-request-failed") {
        userFriendlyMsg = "Lỗi kết nối mạng. Vui lòng kiểm tra lại.";
      } else {
        userFriendlyMsg = error.message;
      }
      showLoginError(userFriendlyMsg);
      loginBtn.disabled = false;
      loginBtn.innerHTML =
        '<i class="fa-solid fa-right-to-bracket"></i> Đăng Nhập';
    });
});

// Logout Event Listener
document.getElementById("btn-logout").addEventListener("click", (e) => {
  e.preventDefault();
  if (confirm("Bạn có chắc chắn muốn đăng xuất khỏi hệ thống admin?")) {
    firebase
      .auth()
      .signOut()
      .catch((error) => {
        alert("Lỗi đăng xuất: " + error.message);
      });
  }
});

// Tab Switching Navigation
const navItems = document.querySelectorAll(".nav-item");
const tabPanes = document.querySelectorAll(".tab-pane");

navItems.forEach((item) => {
  item.addEventListener("click", (e) => {
    e.preventDefault();
    const tab = item.getAttribute("data-tab");

    // Update nav active state
    navItems.forEach((i) => i.classList.remove("active"));
    item.classList.add("active");

    // Show selected tab pane
    tabPanes.forEach((pane) => pane.classList.remove("active"));
    document.getElementById(`tab-${tab}`).classList.add("active");

    // Update top title
    const titles = {
      dashboard: "Bảng Điều Khiển Quản Trị",
      control: "Bảng Can Thiệp Kết Quả Tài Xỉu",
      users: "Quản Lý Tài Khoản Người Dùng",
    };
    document.getElementById("tab-title").innerText =
      titles[tab] || "Quản trị viên";
    activeTab = tab;
  });
});

// ==========================================
// UTC CLOCK SYSTEM (Sync with Flutter Client)
// ==========================================
function startUTCClock() {
  setInterval(() => {
    const nowSeconds = Math.floor(Date.now() / 1000);
    const cyclePosition = nowSeconds % 45;
    const newSessionId = Math.floor(nowSeconds / 45);

    let stateLabel = "";
    let remainingSeconds = 0;

    if (cyclePosition < 30) {
      currentGameState = "BETTING";
      stateLabel = "ĐANG ĐẶT CƯỢC";
      remainingSeconds = 30 - cyclePosition;
    } else if (cyclePosition < 32) {
      currentGameState = "ROLLING";
      stateLabel = "ĐANG LẮC XÚC XẮC";
      remainingSeconds = 0;
    } else {
      currentGameState = "RESULT";
      stateLabel = "KẾT QUẢ PHIÊN";
      remainingSeconds = 45 - cyclePosition;
    }

    // Update timer UI elements
    document.getElementById("countdown-timer").innerText =
      remainingSeconds + "s";
    document.getElementById("current-game-state").innerText = stateLabel;

    if (currentSessionId !== newSessionId) {
      currentSessionId = newSessionId;
      document.getElementById("current-session-id").innerText =
        "#" + currentSessionId;

      // Session changed: sync active cược corresponding to the new session
      syncActiveBets();
    }
  }, 1000);
}

// Start immediately
startUTCClock();

// ==========================================
// REAL-TIME SYSTEM: ACTIVE BETS TRACKING
// ==========================================

function syncActiveBets() {
  if (activeBetsUnsubscribe) {
    activeBetsUnsubscribe();
  }

  if (!db || !firebase.auth().currentUser) return;

  // Listen to current session cược
  activeBetsUnsubscribe = db
    .collection("active_bets")
    .where("sessionId", "==", currentSessionId)
    .onSnapshot(
      (snapshot) => {
        activeBets = [];
        let totalTai = 0;
        let totalXiu = 0;
        let countTai = 0;
        let countXiu = 0;

        const tbody = document.querySelector("#active-bets-table tbody");
        tbody.innerHTML = "";

        if (snapshot.empty) {
          tbody.innerHTML = `<tr><td colspan="5" class="empty-row">Chưa có người chơi nào đặt cược trong phiên này.</td></tr>`;
        } else {
          snapshot.forEach((doc) => {
            const data = doc.data();
            activeBets.push(data);

            if (data.choice === "Tài") {
              totalTai += data.amount;
              countTai++;
            } else if (data.choice === "Xỉu") {
              totalXiu += data.amount;
              countXiu++;
            }

            // Render row
            const timeStr = data.timestamp
              ? new Date(data.timestamp.seconds * 1000).toLocaleTimeString(
                  "vi-VN",
                )
              : "Đang gửi...";
            const choiceClass =
              data.choice === "Tài" ? "color-tai" : "color-xiu";
            const tr = document.createElement("tr");
            tr.innerHTML = `
                        <td><strong>${data.username}</strong></td>
                        <td>#${data.sessionId}</td>
                        <td class="${choiceClass}"><strong>${data.choice}</strong></td>
                        <td class="balance-col">${data.amount.toLocaleString()} COIN</td>
                        <td>${timeStr}</td>
                    `;
            tbody.appendChild(tr);
          });
        }

        // Update summary cards
        document.getElementById("total-bet-tai").innerText =
          totalTai.toLocaleString() + " COIN";
        document.getElementById("total-bet-xiu").innerText =
          totalXiu.toLocaleString() + " COIN";
        document.getElementById("player-count-tai").innerText =
          countTai + " người chơi";
        document.getElementById("player-count-xiu").innerText =
          countXiu + " người chơi";

        // Calculate ratio progress bar
        const totalBets = totalTai + totalXiu;
        let taiPercent = 50;
        let xiuPercent = 50;

        if (totalBets > 0) {
          taiPercent = Math.round((totalTai / totalBets) * 100);
          xiuPercent = 100 - taiPercent;
        }

        document.getElementById("tai-percent").innerText = taiPercent;
        document.getElementById("xiu-percent").innerText = xiuPercent;
        document.getElementById("pool-fill").style.width = taiPercent + "%";
      },
      (error) => {
        console.error("Listen to active bets failed:", error);
      },
    );
}

// ==========================================
// REAL-TIME SYSTEM: GAME CONTROL INTERVENTION
// ==========================================

function syncAdminSettings() {
  if (adminSettingsUnsubscribe) {
    adminSettingsUnsubscribe();
  }

  if (!db || !firebase.auth().currentUser) return;

  adminSettingsUnsubscribe = db
    .collection("game_control")
    .doc("taixiu")
    .onSnapshot(
      (doc) => {
        const summaryDiv = document.getElementById("override-status-summary");

        if (doc.exists && doc.data()) {
          const data = doc.data();
          const forcedSession = data.forcedSessionId;
          const forcedDices = data.forcedDices;
          const forcedResult = data.forcedResult;

          // Show current settings
          if (forcedDices && forcedDices.length === 3) {
            summaryDiv.innerHTML = `
                        <i class="fa-solid fa-circle-dot status-red"></i> 
                        <span>Đang Can Thiệp Phiên <strong>#${forcedSession}</strong>: Ép Ra Điểm Số Cụ Thể 
                            <strong style="color:var(--gold-accent)">[${forcedDices.join(", ")}]</strong> 
                            (${forcedDices.reduce((a, b) => a + b) >= 11 ? "TÀI" : "XỈU"}).
                        </span>`;
          } else if (forcedResult === "Tài" || forcedResult === "Xỉu") {
            const sideClass =
              forcedResult === "Tài" ? "color-tai" : "color-xiu";
            summaryDiv.innerHTML = `
                        <i class="fa-solid fa-circle-dot status-red"></i> 
                        <span>Đang Can Thiệp Phiên <strong>#${forcedSession}</strong>: Ép Kết Quả Ra <strong class="${sideClass}">${forcedResult.toUpperCase()}</strong>.</span>`;
          } else {
            summaryDiv.innerHTML = `<i class="fa-solid fa-circle-dot status-green"></i> <span>Chưa có can thiệp được thiết lập. Xúc xắc sẽ random ngẫu nhiên.</span>`;
          }
        } else {
          summaryDiv.innerHTML = `<i class="fa-solid fa-circle-dot status-green"></i> <span>Chưa có can thiệp được thiết lập. Xúc xắc sẽ random ngẫu nhiên.</span>`;
        }
      },
      (error) => {
        console.error("Listen to admin settings failed:", error);
      },
    );
}

syncAdminSettings();

// Actions: Apply Intervention
document.getElementById("btn-apply-override").addEventListener("click", () => {
  if (!db) {
    alert("Chưa kết nối cơ sở dữ liệu Firebase!");
    return;
  }

  // Determine the target session ID to override
  const nowSeconds = Math.floor(Date.now() / 1000);
  const cyclePosition = nowSeconds % 45;
  const currentSession = Math.floor(nowSeconds / 45);

  // If current state is RESULT (evaluation already done), apply to upcoming session. Otherwise, apply to the current active session.
  const targetSession =
    cyclePosition >= 32 ? currentSession + 1 : currentSession;

  // Read Outcome Radio
  const radios = document.getElementsByName("force-outcome");
  let selectedOutcome = "None";
  for (const radio of radios) {
    if (radio.checked) {
      selectedOutcome = radio.value;
      break;
    }
  }

  // Read Custom Dice Inputs
  const d1 = parseInt(document.getElementById("dice-val-1").value);
  const d2 = parseInt(document.getElementById("dice-val-2").value);
  const d3 = parseInt(document.getElementById("dice-val-3").value);

  let forcedDices = null;
  let forcedResult = null;

  if (d1 > 0 && d2 > 0 && d3 > 0) {
    // Force exact dice values
    forcedDices = [d1, d2, d3];
    forcedResult = null;
  } else if (selectedOutcome === "Tài" || selectedOutcome === "Xỉu") {
    // Force direction
    forcedDices = null;
    forcedResult = selectedOutcome;
  } else {
    // Clear override
    forcedDices = null;
    forcedResult = null;
  }

  // Write override settings to Firestore
  const taixiuPromise = db.collection("game_control").doc("taixiu").set({
    forcedSessionId: targetSession,
    forcedDices: forcedDices,
    forcedResult: forcedResult,
  });

  let historyPromise = Promise.resolve();
  if (forcedDices || forcedResult) {
    const updateData = {};
    updateData[`overrides.${targetSession}`] = {
      dices: forcedDices,
      result: forcedResult,
    };
    historyPromise = db
      .collection("game_control")
      .doc("history_overrides")
      .update(updateData)
      .catch(() => {
        const initData = { overrides: {} };
        initData.overrides[targetSession] = {
          dices: forcedDices,
          result: forcedResult,
        };
        return db
          .collection("game_control")
          .doc("history_overrides")
          .set(initData);
      });
  }

  Promise.all([taixiuPromise, historyPromise])
    .then(() => {
      alert(`Đã áp dụng can thiệp thành công cho phiên đấu #${targetSession}!`);
    })
    .catch((e) => {
      alert("Lỗi lưu cấu hình: " + e.message);
    });
});

// Actions: Reset Intervention
document.getElementById("btn-reset-override").addEventListener("click", () => {
  if (!db) return;

  db.collection("game_control")
    .doc("taixiu")
    .delete()
    .then(() => {
      alert("Đã xóa hoàn toàn mọi can thiệp!");
      document.getElementById("dice-val-1").value = "0";
      document.getElementById("dice-val-2").value = "0";
      document.getElementById("dice-val-3").value = "0";
      document.getElementsByName("force-outcome")[0].checked = true;
    })
    .catch((e) => {
      alert("Lỗi reset cấu hình: " + e.message);
    });
});

// ==========================================
// REAL-TIME SYSTEM: REGISTERED USERS MANAGEMENT
// ==========================================

function syncUsersList() {
  if (usersUnsubscribe) {
    usersUnsubscribe();
  }

  if (!db || !firebase.auth().currentUser) return;

  usersUnsubscribe = db.collection("users").onSnapshot(
    (snapshot) => {
      registeredUsers = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        registeredUsers.push(data);
      });
      renderUsersTable();
    },
    (error) => {
      console.error("Listen to users collection failed:", error);
    },
  );
}

syncUsersList();

// Render Users Table with Filter
function renderUsersTable() {
  const tbody = document.querySelector("#users-table tbody");
  tbody.innerHTML = "";

  const searchVal = document
    .getElementById("search-users")
    .value.toLowerCase()
    .trim();

  const filteredUsers = registeredUsers.filter((u) => {
    const username = u.username || "";
    const fullName = u.fullName || "";
    const idCode = u.idCode || "";
    return (
      username.toLowerCase().includes(searchVal) ||
      fullName.toLowerCase().includes(searchVal) ||
      idCode.toLowerCase().includes(searchVal)
    );
  });

  if (filteredUsers.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" class="empty-row">Không tìm thấy tài khoản người dùng phù hợp.</td></tr>`;
  } else {
    filteredUsers.forEach((u) => {
      const tr = document.createElement("tr");
      tr.innerHTML = `
                <td><code>${u.idCode || ""}</code></td>
                <td><strong>${u.username || ""}</strong></td>
                <td>${u.fullName || ""}</td>
                <td>${u.phoneNumber || "N/A"}</td>
                <td><span class="badge-vip">VIP ${u.vipLevel || 0}</span></td>
                <td class="balance-col">${(u.balance || 0).toLocaleString()} COIN</td>
                <td>
                    <button class="btn btn-sm btn-gold-outline" onclick="openBalanceModal('${u.uid}', '${u.username || ""}', ${u.balance || 0})">
                        <i class="fa-solid fa-wallet"></i> Cộng / Trừ COIN
                    </button>
                </td>
            `;
      tbody.appendChild(tr);
    });
  }
}

// User Search Handler
document
  .getElementById("search-users")
  .addEventListener("input", renderUsersTable);

// ==========================================
// MODAL BALANCE DIALOG
// ==========================================
const modal = document.getElementById("balance-modal");

window.openBalanceModal = function (uid, username, currentBalance) {
  selectedUserIdForBalance = uid;
  document.getElementById("modal-username").innerText = username;
  document.getElementById("modal-current-balance").innerText =
    currentBalance.toLocaleString() + " COIN";
  document.getElementById("modal-input-amount").value = "";
  modal.classList.add("active");
};

function closeModal() {
  modal.classList.remove("active");
  selectedUserIdForBalance = null;
}

document
  .getElementById("btn-close-modal")
  .addEventListener("click", closeModal);
document
  .getElementById("btn-cancel-balance")
  .addEventListener("click", closeModal);

window.adjustAmount = function (amount) {
  const input = document.getElementById("modal-input-amount");
  let current = parseFloat(input.value) || 0;
  input.value = current + amount;
};

// Save Balance Change (using transaction to prevent conflicts)
document.getElementById("btn-save-balance").addEventListener("click", () => {
  if (!db || !selectedUserIdForBalance) return;

  const amountInput = document.getElementById("modal-input-amount").value;
  const amountChange = parseFloat(amountInput);

  if (isNaN(amountChange) || amountChange === 0) {
    alert("Vui lòng nhập số coin hợp lệ!");
    return;
  }

  const userDocRef = db.collection("users").doc(selectedUserIdForBalance);

  db.runTransaction((transaction) => {
    return transaction.get(userDocRef).then((doc) => {
      if (!doc.exists) {
        throw "Người dùng không tồn tại!";
      }

      const currentBalance = doc.data().balance || 0;
      const newBalance = currentBalance + amountChange;

      if (newBalance < 0) {
        throw "Không thể thực hiện trừ xu vì số dư tài khoản sẽ bị âm!";
      }

      transaction.update(userDocRef, {
        balance: newBalance,
      });
    });
  })
    .then(() => {
      alert("Đã cập nhật số dư thành công!");
      closeModal();
    })
    .catch((error) => {
      alert("Lỗi giao dịch: " + error);
    });
});
