// @ts-nocheck
import React, { useEffect, useState, useLayoutEffect, useContext, useCallback } from "react";
import {View,Text,Image,StyleSheet,ActivityIndicator,TouchableOpacity,ScrollView,TextInput,Alert,} from "react-native";
import * as ImagePicker from "expo-image-picker";
import { Menu } from "react-native-paper";
import { graphqlRequest } from "../services/api";
import { useLogout } from "../hooks/Logout";
import { useNavigation, useFocusEffect } from "@react-navigation/native";
import { UserContext } from "../components/ui/UserContext";
import { LinearGradient } from "expo-linear-gradient";

const QUERY = `
query {
  currentUser {
    id
    name
    companyName
    profilePic
    admin
  }
  companyProfile {
    ownerName
    companyName
    phone
    address
    seal 
    authorizedSignature
  }
}
`;

const UPDATE_PROFILE_PIC = `
mutation UpdateProfilePic($profilePic: String!) {
  updateProfile(profilePic: $profilePic) {
    success
    user {
      profilePic
    }
  }
}
`;

const SAVE_COMPANY = `
mutation SaveCompany(
  $ownerName: String!
  $companyName: String!
  $phone: String!
  $address: String!
  $seal: Upload
  $authorizedSignature: Upload
) {
  createOrUpdateCompanyProfile(
    ownerName: $ownerName
    companyName: $companyName
    phone: $phone
    address: $address
    seal: $seal
    authorizedSignature: $authorizedSignature
  ) {
    success
    message
  }
}
`;

export default function Profile() {
  const { token } = useContext(UserContext);
  const navigation = useNavigation();
  const logout = useLogout();

  const [loading, setLoading] = useState(true);
  const [menuVisible, setMenuVisible] = useState(false);
  const [editMode, setEditMode] = useState(false);

  const [profilePic, setProfilePic] = useState("");
  const [ownerName, setOwnerName] = useState("");
  const [companyName, setCompanyName] = useState("");
  const [phone, setPhone] = useState("");
  const [address, setAddress] = useState("");

  const [seal, setSeal] = useState(null);
  const [authorizedSignature, setAuthorizedSignature] = useState(null);

  useFocusEffect(useCallback(() => () => setMenuVisible(false), []));

  useEffect(() => {
    loadProfile();
  }, []);

  const loadProfile = async () => {
    try {
      const res = await graphqlRequest(QUERY, {}, token);
      setProfilePic(res.currentUser?.profilePic || "");
      setOwnerName(res.companyProfile?.ownerName || res.currentUser?.name || "");
      setCompanyName(res.companyProfile?.companyName || res.currentUser?.companyName ||"");
      setPhone(res.companyProfile?.phone || "");
      setAddress(res.companyProfile?.address || "");
      setSeal(res.companyProfile?.seal ? { uri: res.companyProfile.seal, isRemote:true} : null);
      setAuthorizedSignature(res.companyProfile?.authorizedSignature ? { uri: res.companyProfile.authorizedSignature, isRemote:true}: null);
    } catch (e) {
      console.log(e);
    } finally {
      setLoading(false);
    }
  };

  const pickProfilePic = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      quality: 0.7,
      base64: true,
    });

    if (result.canceled) return;

    const base64 = `data:image/jpeg;base64,${result.assets[0].base64}`;

    try {
      const res = await graphqlRequest(
        UPDATE_PROFILE_PIC,
        { profilePic: base64 },
        token
      );

      if (res.updateProfile.success) {
        setProfilePic(res.updateProfile.user.profilePic);
      }
    } catch {
      Alert.alert("Error", "Profile image upload failed");
    }
  };

  const pickFile = async (setter) => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      quality: 1,
    });

    if (!result.canceled) {
      setter({
        uri: result.assets[0].uri,
        name: "upload.png",
        type: "image/png",
      });
    }
  };
  console.log("SIGNATURE",authorizedSignature);
  console.log("SEAL",seal);
  console.log("PROFILE PIC",profilePic);

const saveCompany = async () => {
  if(!/^[0-9]{10}$/.test(phone)){
    Alert.alert("Invalid phone number","Please enter a valid 10-digit number");
    return;
  }

  const variables = { ownerName, companyName, phone, address };

  if(seal && !seal.isRemote){
    variables.seal = seal;
  }

  if(authorizedSignature && !authorizedSignature.isRemote){
    variables.authorizedSignature = authorizedSignature;
  }

  try {
    const res = await graphqlRequest(
      SAVE_COMPANY,
      variables,
      token,
      true
    );

    if (res.createOrUpdateCompanyProfile.success) {
      Alert.alert("Success", "Profile updated");
      setEditMode(false);
      loadProfile();
    }
  } catch(e) {
    console.log(e);
    Alert.alert("Error", "Save failed");
  }
};


  useLayoutEffect(() => {
    navigation.setOptions({
      title: "Profile",
      headerStyle: { backgroundColor: "#8B5CF6" },
      headerTintColor: "#fff",
      headerRight: () => (
        <Menu
          visible={menuVisible}
          onDismiss={() => setMenuVisible(false)}
          anchor={
            <TouchableOpacity onPress={() => setMenuVisible(true)} style={{ marginRight: 16 }}>
              <Text style={{ fontSize: 22, color: "#fff" }}>☰</Text>
            </TouchableOpacity>
          }
        >
          <Menu.Item title="Edit Profile" onPress={() => setEditMode(true)} />
          <Menu.Item title="Logout" onPress={logout} />
        </Menu>
      ),
    });
  }, [menuVisible]);

  if (loading) {
    return (
      <LinearGradient colors={["#8B5CF6", "#A78BFA"]} style={styles.center}>
        <ActivityIndicator size="large" color="#fff" />
      </LinearGradient>
    );
  }

  return (  
    <View style={{ flex: 1, backgroundColor: "#F3F4F6" }}>
      <ScrollView contentContainerStyle={{ paddingBottom: 140 }}>
        <LinearGradient colors={["#8B5CF6", "#A78BFA"]} style={styles.header}>
          <Text style={styles.headerTitle}>My Profile</Text>
          <Text style={styles.headerSubtitle}>Manage your account</Text>
        </LinearGradient>

        <View style={styles.card}>
          {/* AVATAR */}
          <View style={styles.avatarWrapper}>
            <TouchableOpacity onPress={pickProfilePic}>
              <Image
                source={
                  profilePic
                    ? { uri: profilePic }
                    : require("../assets/images/default-avatar.png")
                }
                style={styles.avatar}
              />
              <View style={styles.cameraBadge}>
                <Text style={{ color: "#fff" }}>📷</Text>
              </View>
            </TouchableOpacity>
          </View>

          <Text style={styles.tapText}>Tap to change profile picture</Text>

          {/* ================= VIEW MODE ================= */}
          {!editMode && (
            <View style={styles.infoCard}>
              {/* NAME */}
              <View style={styles.infoRow}>
                <View style={styles.infoIcon}><Text style={styles.iconEmoji}>👤</Text></View>
                <Text style={styles.infoText}>{ownerName}</Text>
              </View>

              {/* COMPANY */}
              <View style={styles.infoRow}>
                <View style={styles.infoIcon}><Text style={styles.iconEmoji}>🏢</Text></View>
                <Text style={styles.infoText}>{companyName}</Text>
              </View>

              {/* PHONE */}
              <View style={styles.infoRow}>
                <View style={styles.infoIcon}><Text style={styles.iconEmoji}>📱</Text></View>
                <Text style={styles.infoText}>{phone || "Not added"}</Text>
              </View>

              {/* ADDRESS */}
              <View style={styles.infoRow}>
                <View style={styles.infoIcon}><Text style={styles.iconEmoji}>📍</Text></View>
                <Text style={styles.infoText}>{address || "Not added"}</Text>
              </View>
            </View>
          )}

          {editMode && (
            <View style={styles.editCard}>
              <TextInput style={styles.input} value={ownerName} onChangeText={setOwnerName} placeholder="Owner Name" />
              <TextInput style={styles.input} value={companyName} onChangeText={setCompanyName} placeholder="Company Name" />
              <TextInput style={styles.input} value={phone} onChangeText={(text) =>{const numberic=text.replace(/[^0-9]/g,""); setPhone(numberic);}} placeholder="Phone" keyboardType="number-pad" maxLength={10}/>
              <TextInput
                style={[styles.input, { height: 80 }]}
                value={address}
                onChangeText={setAddress}
                placeholder="Address"
                multiline
              />

              {/* SEAL */}
              <Text style={styles.label}>Company Seal</Text>
              <TouchableOpacity style={styles.uploadBox} onPress={() => pickFile(setSeal)}>
                {seal ? <Image source={{ uri: seal.uri }} style={styles.sealImg} /> : <Text>Upload Seal</Text>}
              </TouchableOpacity>

              {/* SIGNATURE */}
              <Text style={styles.label}>Authorized Signature</Text>
              <TouchableOpacity style={styles.uploadBox} onPress={() => pickFile(setAuthorizedSignature)}>
                {authorizedSignature ? (
                  <Image source={{ uri: authorizedSignature.uri }} style={styles.signatureImg} />
                ) : (
                  <Text>Upload Signature</Text>
                )}
              </TouchableOpacity>

              <View style={styles.editActions}>
                <TouchableOpacity onPress={() => setEditMode(false)}>
                  <Text style={{ color: "#6B7280" }}>Cancel</Text>
                </TouchableOpacity>

                <TouchableOpacity style={styles.saveBtn} onPress={saveCompany}>
                  <Text style={{ color: "#fff", fontWeight: "700" }}>Save</Text>
                </TouchableOpacity>
              </View>
            </View>
          )}
        </View>
      </ScrollView>

      {/* BOTTOM BAR */}
      <View style={styles.bottomBar}>
        <TouchableOpacity style={styles.bottomButton} onPress={() => navigation.navigate("CreateRepairRequest")}>
          <View style={styles.bottomCircle}>
            <Text style={styles.bottomIcon}>➕</Text>
          </View>
          <Text style={styles.bottomLabel}>Create</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.bottomButton} onPress={() => navigation.navigate("ViewRequest")}>
          <View style={styles.bottomCircle}>
            <Text style={styles.bottomIcon}>📋</Text>
          </View>
          <Text style={styles.bottomLabel}>View</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.bottomButton} onPress={() => navigation.navigate("AdminEstimation")}>
          <View style={styles.bottomCircle}>
            <Text style={styles.bottomIcon}>✅</Text>
          </View>
          <Text style={styles.bottomLabel}>Estimation</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}


const styles = StyleSheet.create({
  center: { flex: 1, justifyContent: "center", alignItems: "center" },

  header: { height: 180, padding: 24 },
  headerTitle: { fontSize: 23, fontWeight: "700", color: "#fff" },
  headerSubtitle: { color: "#EDE9FE" },

  card: {
    backgroundColor: "#fff",
    margin: 20,
    borderRadius: 30,
    paddingTop: 80,
    paddingHorizontal: 24,
    paddingBottom: 24,
    marginTop: -60,
  },

  avatarWrapper: {
    position: "absolute",
    top: -60,
    alignSelf: "center",
  },

  avatar: {
    width: 120,
    height: 120,
    borderRadius: 60,
    borderWidth: 6,
    borderColor: "#fff",
    backgroundColor: "#EEE",
  },

  cameraBadge: {
    position: "absolute",
    bottom: 6,
    right: 6,
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: "#8B5CF6",
    justifyContent: "center",
    alignItems: "center",
    borderWidth: 2,
    borderColor: "#fff",
  },

  tapText: {
    textAlign: "center",
    color: "#8B5CF6",
    fontWeight: "600",
    marginBottom: 20,
  },

  infoCard: {
    backgroundColor: "#F9FAFB",
    borderRadius: 20,
    padding: 20,
  },

  infoRow: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "#fff",
    padding: 16,
    borderRadius: 14,
    marginBottom: 14,
  },

  infoIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "#EDE9FE",
    justifyContent: "center",
    alignItems: "center",
    marginRight: 14,
  },

  iconEmoji: {
    fontSize: 20,
  },

  infoText: { fontSize: 16, fontWeight: "500", color: "#1F2937" },

  editCard: {
    backgroundColor: "#F9FAFB",
    borderRadius: 20,
    padding: 16,
  },

  input: {
    backgroundColor: "#fff",
    borderWidth: 1,
    borderColor: "#E5E7EB",
    borderRadius: 14,
    padding: 14,
    marginBottom: 12,
  },

  label: { fontWeight: "600", marginTop: 16, marginBottom: 8 },

  uploadBox: {
    height: 110,
    borderWidth: 1,
    borderColor: "#DDD",
    borderRadius: 14,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#fff",
    marginBottom: 12,
  },

  editActions: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginTop: 10,
  },

  saveBtn: {
    backgroundColor: "#8B5CF6",
    paddingHorizontal: 28,
    paddingVertical: 14,
    borderRadius: 14,
  },

  sealImg: { width: 80, height: 80, resizeMode: "contain" },
  signatureImg: { width: 160, height: 60, resizeMode: "contain" },

  bottomBar: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    height: 90,
    backgroundColor: "#fff",
    flexDirection: "row",
    justifyContent: "space-around",
    alignItems: "center",
    paddingBottom: 10,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 10,
  },

  bottomButton: {
    alignItems: "center",
    justifyContent: "center",
  },

  bottomCircle: {
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: "#8B5CF6",
    justifyContent: "center",
    alignItems: "center",
    marginBottom: 6,
    shadowColor: "#8B5CF6",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 6,
  },

  bottomIcon: {
    fontSize: 24,
  },

  bottomLabel: {
    fontSize: 13,
    color: "#6B7280",
    fontWeight: "500",
  },
});
