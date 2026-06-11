"use strict";
/**
 * Zerocks Cloud Functions — Barrel Export
 *
 * All Cloud Functions are exported from this file.
 * Firebase Functions v5 (2nd gen) with modular syntax.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifyPayment = exports.createRazorpayOrder = exports.setCustomClaims = exports.cleanupExpired = exports.generateSignedUrl = exports.onJobCompleted = exports.onJobCreated = void 0;
const admin = __importStar(require("firebase-admin"));
// Initialize Firebase Admin SDK (once, before any function imports)
admin.initializeApp();
// Export all functions
var onJobCreated_1 = require("./onJobCreated");
Object.defineProperty(exports, "onJobCreated", { enumerable: true, get: function () { return onJobCreated_1.onJobCreated; } });
var onJobCompleted_1 = require("./onJobCompleted");
Object.defineProperty(exports, "onJobCompleted", { enumerable: true, get: function () { return onJobCompleted_1.onJobStatusChanged; } });
var generateSignedUrl_1 = require("./generateSignedUrl");
Object.defineProperty(exports, "generateSignedUrl", { enumerable: true, get: function () { return generateSignedUrl_1.generateSignedUrl; } });
var cleanupExpired_1 = require("./cleanupExpired");
Object.defineProperty(exports, "cleanupExpired", { enumerable: true, get: function () { return cleanupExpired_1.cleanupExpiredJobs; } });
var setCustomClaims_1 = require("./setCustomClaims");
Object.defineProperty(exports, "setCustomClaims", { enumerable: true, get: function () { return setCustomClaims_1.setCustomClaims; } });
var createRazorpayOrder_1 = require("./createRazorpayOrder");
Object.defineProperty(exports, "createRazorpayOrder", { enumerable: true, get: function () { return createRazorpayOrder_1.createRazorpayOrder; } });
var verifyPayment_1 = require("./verifyPayment");
Object.defineProperty(exports, "verifyPayment", { enumerable: true, get: function () { return verifyPayment_1.verifyPayment; } });
//# sourceMappingURL=index.js.map